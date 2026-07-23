# frozen_string_literal: true

module WGPU
  class ShaderModule
    attr_reader :handle

    # Creates a shader module from WGSL, GLSL, or SPIR-V input.
    # @param device [Device] owning device
    # @param code [String, Array<Integer>, nil] shader source or binary
    # @param spirv [String, Array<Integer>, nil] explicit SPIR-V input
    # @param validate [Boolean] whether to fetch and raise compilation errors
    # @raise [ShaderError] if native validation, creation, or compilation fails
    def initialize(device, label: nil, code: nil, spirv: nil, compilation_hints: [], validate: false)
      @device = device
      @pointers = []
      @compilation_hints = compilation_hints
      source = select_source(code, spirv)

      source_ptr = build_shader_source(source, label: label)

      desc = Native::ShaderModuleDescriptor.new
      desc[:next_in_chain] = source_ptr
      if label
        label_ptr = FFI::MemoryPointer.from_string(label)
        @pointers << label_ptr
        desc[:label][:data] = label_ptr
        desc[:label][:length] = label.bytesize
      else
        desc[:label][:data] = nil
        desc[:label][:length] = 0
      end

      device.push_error_scope(:validation)
      @handle = Native.wgpuDeviceCreateShaderModule(device.handle, desc)
      error = device.pop_error_scope

      if @handle.null? || (error[:type] && error[:type] != :no_error)
        msg = error[:message] || "Failed to create shader module"
        raise ShaderError, shader_error_message(msg, label)
      end

      return unless validate

      begin
        validate_compilation!(label)
      rescue StandardError
        release
        raise
      end
    end

    # Fetches compiler diagnostics for the shader.
    # @return [Hash] request status and compilation messages
    # @raise [ShaderError] if the pinned native library cannot provide diagnostics
    def get_compilation_info
      unless Native.compilation_info_available?
        raise ShaderError,
          "Shader compilation info is not implemented by wgpu-native #{Native::Distribution::VERSION}"
      end

      result_holder = { done: false, status: nil, messages: [] }
      instance = @device.adapter&.instance

      callback_token = nil
      callback = FFI::Function.new(
        :void, [:uint32, :pointer, :pointer, :pointer]
      ) do |status, compilation_info_ptr, _userdata1, _userdata2|
        begin
          result_holder[:status] = Native::CompilationInfoRequestStatus[status]

          unless compilation_info_ptr.null?
            info = Native::CompilationInfo.new(compilation_info_ptr)
            count = info[:message_count]
            if count > 0 && !info[:messages].null?
              count.times do |i|
                msg_ptr = info[:messages] + (i * Native::CompilationMessage.size)
                msg = Native::CompilationMessage.new(msg_ptr)
                message_text = if msg[:message][:data] && !msg[:message][:data].null? && msg[:message][:length] > 0
                                 msg[:message][:data].read_string(msg[:message][:length])
                               else
                                 ""
                               end
                result_holder[:messages] << CompilationMessage.new(
                  type: msg[:type],
                  message: message_text,
                  line_num: msg[:line_num],
                  line_pos: msg[:line_pos],
                  offset: msg[:offset],
                  length: msg[:length]
                )
              end
            end
          end
          result_holder[:done] = true
        ensure
          CallbackKeepalive.release(self, callback_token)
        end
      end

      callback_info = Native::CompilationInfoCallbackInfo.new
      callback_info[:next_in_chain] = nil
      callback_info[:mode] = AsyncWaiter.callback_mode(instance: instance)
      callback_info[:callback] = callback
      callback_info[:userdata1] = nil
      callback_info[:userdata2] = nil

      callback_token = CallbackKeepalive.retain(self, callback)
      future =
        begin
          Native.wgpuShaderModuleGetCompilationInfo(@handle, callback_info)
        rescue StandardError
          CallbackKeepalive.release(self, callback_token)
          raise
        end
      AsyncWaiter.wait(status_holder: result_holder, instance: instance, device: @device, future: future)

      {
        status: result_holder[:status],
        messages: result_holder[:messages]
      }
    end

    # Fetches compiler diagnostics on a background task.
    # @return [AsyncTask] task yielding compilation information
    def get_compilation_info_async
      AsyncTask.new { get_compilation_info }
    end

    # Releases the native shader module handle.
    #
    # Calling this method more than once has no effect.
    # @return [void]
    def release
      return if @handle.null?
      Native.wgpuShaderModuleRelease(@handle)
      @handle = FFI::Pointer::NULL
    end

    private

    def select_source(code, spirv)
      sources = [code, spirv].reject(&:nil?)
      raise ArgumentError, "provide exactly one of code: or spirv:" unless sources.one?

      sources.first
    end

    def validate_compilation!(label)
      info = get_compilation_info
      errors = info[:messages].select { |message| message.type == :error }
      return if errors.empty?

      details = errors.map(&:to_s).join("\n")
      release
      raise ShaderError, shader_error_message(details, label)
    end

    def shader_error_message(message, label)
      context = label ? " for #{label.inspect}" : ""
      "Shader compilation failed#{context}: #{message}"
    end

    def build_shader_source(code, label:)
      if code.is_a?(String)
        if spirv_binary?(code)
          build_spirv_source(code.b)
        elsif glsl_source?(code)
          build_glsl_source(code, label: label)
        else
          build_wgsl_source(code)
        end
      elsif code.is_a?(Array)
        build_spirv_source(code.pack("L<*"))
      elsif code.respond_to?(:to_str)
        build_shader_source(code.to_str, label: label)
      else
        # Assume binary SPIR-V for byte-like objects.
        build_spirv_source(code)
      end
    end

    def glsl_source?(source)
      source.lstrip.start_with?("#version")
    end

    def spirv_binary?(source)
      source.bytesize >= 4 && source.byteslice(0, 4).bytes == [0x03, 0x02, 0x23, 0x07]
    end

    def build_wgsl_source(source)
      code_ptr = FFI::MemoryPointer.from_string(source)
      @pointers << code_ptr

      wgsl = Native::ShaderSourceWGSL.new
      wgsl[:chain][:next] = nil
      wgsl[:chain][:s_type] = :shader_source_wgsl
      wgsl[:code][:data] = code_ptr
      wgsl[:code][:length] = source.bytesize

      @pointers << wgsl
      wgsl.to_ptr
    end

    def build_spirv_source(binary)
      bytes =
        if binary.is_a?(String)
          binary
        elsif binary.respond_to?(:to_str)
          binary.to_str
        elsif binary.respond_to?(:to_a)
          binary.to_a.pack("C*")
        else
          raise ArgumentError, "Unsupported SPIR-V data type: #{binary.class}"
        end

      raise ArgumentError, "SPIR-V bytecode size must be a multiple of 4" if (bytes.bytesize % 4) != 0

      byte_ptr = FFI::MemoryPointer.new(:char, bytes.bytesize)
      byte_ptr.put_bytes(0, bytes)
      @pointers << byte_ptr

      spirv = Native::ShaderSourceSPIRV.new
      spirv[:chain][:next] = nil
      spirv[:chain][:s_type] = :shader_source_spirv
      spirv[:code_size] = bytes.bytesize / 4
      spirv[:code] = byte_ptr

      @pointers << spirv
      spirv.to_ptr
    end

    def build_glsl_source(source, label:)
      stage = shader_stage_for_glsl(label)
      raise ArgumentError, "GLSL shader requires label containing comp/vert/frag" if stage.nil?

      code_ptr = FFI::MemoryPointer.from_string(source)
      @pointers << code_ptr

      glsl = Native::ShaderSourceGLSL.new
      glsl[:chain][:next] = nil
      glsl[:chain][:s_type] = :shader_source_glsl
      glsl[:stage] = stage
      glsl[:code][:data] = code_ptr
      glsl[:code][:length] = source.bytesize
      glsl[:define_count] = 0
      glsl[:defines] = nil

      @pointers << glsl
      glsl.to_ptr
    end

    def shader_stage_for_glsl(label)
      return nil unless label

      down = label.downcase
      return Native::ShaderStage[:compute] if down.include?("comp")
      return Native::ShaderStage[:vertex] if down.include?("vert")
      return Native::ShaderStage[:fragment] if down.include?("frag")

      nil
    end
  end
end
