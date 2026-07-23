# frozen_string_literal: true

module WGPU
  class Device
    attr_reader :handle, :queue, :adapter

    LIMIT_FIELDS = Native::Limits.members.freeze

    # Requests a logical device and waits for the native callback.
    #
    # @param adapter [Adapter] adapter that will create the device
    # @param label [String, nil] optional debugging label
    # @param required_features [Array<Symbol, Integer>] features the device must enable
    # @param required_limits [Hash, nil] minimum required limits
    # @param timeout [Numeric, nil] maximum wait time in seconds
    # @return [Device] requested device
    # @raise [DeviceError] if device creation fails
    # @raise [TimeoutError] if the request exceeds +timeout+
    def self.request(adapter, label: nil, required_features: [], required_limits: nil, timeout: nil)
      device_ptr = FFI::MemoryPointer.new(:pointer)
      status_holder = { done: false, value: nil, message: nil }
      device_callback_state = {
        mutex: Mutex.new,
        uncaptured_error: nil,
        device_lost: nil
      }

      callback = FFI::Function.new(
        :void, [:uint32, :pointer, Native::StringView.by_value, :pointer, :pointer]
      ) do |status, device, message, _userdata1, _userdata2|
        status_holder[:value] = Native::RequestDeviceStatus[status]
        if message[:data] && !message[:data].null? && message[:length] > 0
          status_holder[:message] = message[:data].read_string(message[:length])
        end
        device_ptr.write_pointer(device)
        status_holder[:done] = true
      end

      queue_desc = Native::QueueDescriptor.new
      queue_desc[:next_in_chain] = nil
      queue_desc[:label][:data] = nil
      queue_desc[:label][:length] = 0

      device_lost_info = Native::DeviceLostCallbackInfo.new
      device_lost_info[:next_in_chain] = nil
      device_lost_info[:mode] = AsyncWaiter.callback_mode(instance: adapter.instance)
      device_lost_callback = build_device_lost_callback(device_callback_state)
      device_lost_info[:callback] = device_lost_callback
      device_lost_info[:userdata1] = nil
      device_lost_info[:userdata2] = nil

      error_info = Native::UncapturedErrorCallbackInfo.new
      error_info[:next_in_chain] = nil
      uncaptured_error_callback = build_uncaptured_error_callback(device_callback_state)
      error_info[:callback] = uncaptured_error_callback
      error_info[:userdata1] = nil
      error_info[:userdata2] = nil

      desc = Native::DeviceDescriptor.new
      desc[:next_in_chain] = nil
      if label
        label_ptr = FFI::MemoryPointer.from_string(label)
        desc[:label][:data] = label_ptr
        desc[:label][:length] = label.bytesize
      else
        desc[:label][:data] = nil
        desc[:label][:length] = 0
      end

      feature_values = normalize_required_features(required_features)
      if feature_values.empty?
        desc[:required_feature_count] = 0
        desc[:required_features] = nil
      else
        features_ptr = FFI::MemoryPointer.new(:uint32, feature_values.size)
        features_ptr.write_array_of_uint32(feature_values)
        desc[:required_feature_count] = feature_values.size
        desc[:required_features] = features_ptr
      end

      required_limits_struct = build_required_limits(adapter, required_limits)
      desc[:required_limits] = required_limits_struct ? required_limits_struct.to_ptr : nil
      desc[:default_queue] = queue_desc
      desc[:device_lost_callback_info] = device_lost_info
      desc[:uncaptured_error_callback_info] = error_info

      callback_info = Native::RequestDeviceCallbackInfo.new
      callback_info[:next_in_chain] = nil
      callback_info[:mode] = AsyncWaiter.callback_mode(instance: adapter.instance)
      callback_info[:callback] = callback
      callback_info[:userdata1] = nil
      callback_info[:userdata2] = nil

      callback_token = CallbackKeepalive.retain(adapter, callback)
      begin
        future = Native.wgpuAdapterRequestDevice(adapter.handle, desc, callback_info)
        AsyncWaiter.wait(
          status_holder: status_holder,
          instance: adapter.instance,
          future: future,
          timeout: timeout
        )
      ensure
        CallbackKeepalive.release(adapter, callback_token)
      end

      handle = device_ptr.read_pointer
      if handle.null? || status_holder[:value] != :success
        msg = status_holder[:message] || "Unknown error"
        raise DeviceError, "Failed to request device: #{msg}"
      end

      device = new(handle, adapter: adapter, label: label, callback_state: device_callback_state)
      device.send(:retain_device_callback, device_lost_callback)
      device.send(:retain_device_callback, uncaptured_error_callback)
      device
    end

    def initialize(handle, adapter: nil, label: nil, callback_state: nil)
      @handle = handle
      @adapter = adapter
      @label = label
      @device_callback_state = callback_state || {
        mutex: Mutex.new,
        uncaptured_error: nil,
        device_lost: nil
      }
      @device_callback_tokens = []
      @queue = Queue.new(Native.wgpuDeviceGetQueue(@handle), device: self)
    end

    def adapter_info
      @adapter&.info
    end

    def create_buffer(label: nil, size:, usage:, mapped_at_creation: false)
      Buffer.new(self, label: label, size: size, usage: usage, mapped_at_creation: mapped_at_creation)
    end

    def create_shader_module(label: nil, code: nil, spirv: nil, compilation_hints: [], validate: false)
      ShaderModule.new(
        self,
        label: label,
        code: code,
        spirv: spirv,
        compilation_hints: compilation_hints,
        validate: validate
      )
    end

    def create_command_encoder(label: nil)
      CommandEncoder.new(self, label: label)
    end

    def create_bind_group_layout(label: nil, entries:)
      BindGroupLayout.new(self, label: label, entries: entries)
    end

    def create_bind_group(label: nil, layout:, entries:)
      BindGroup.new(self, label: label, layout: layout, entries: entries)
    end

    def create_pipeline_layout(label: nil, bind_group_layouts:)
      PipelineLayout.new(self, label: label, bind_group_layouts: bind_group_layouts)
    end

    def create_compute_pipeline(label: nil, layout:, compute:)
      ComputePipeline.new(self, label: label, layout: layout, compute: compute)
    end

    def create_compute_pipeline_async(label: nil, layout:, compute:)
      AsyncTask.new do
        create_compute_pipeline(label: label, layout: layout, compute: compute)
      end
    end

    def create_render_pipeline(label: nil, layout:, vertex:, primitive: {}, depth_stencil: nil, multisample: {}, fragment: nil)
      RenderPipeline.new(self,
        label: label,
        layout: layout,
        vertex: vertex,
        primitive: primitive,
        depth_stencil: depth_stencil,
        multisample: multisample,
        fragment: fragment
      )
    end

    def create_render_pipeline_async(label: nil, layout:, vertex:, primitive: {}, depth_stencil: nil, multisample: {}, fragment: nil)
      AsyncTask.new do
        create_render_pipeline(
          label: label,
          layout: layout,
          vertex: vertex,
          primitive: primitive,
          depth_stencil: depth_stencil,
          multisample: multisample,
          fragment: fragment
        )
      end
    end

    def create_texture(label: nil, size:, format:, usage:, dimension: :d2, mip_level_count: 1, sample_count: 1, view_formats: [])
      Texture.new(self,
        label: label,
        size: size,
        format: format,
        usage: usage,
        dimension: dimension,
        mip_level_count: mip_level_count,
        sample_count: sample_count,
        view_formats: view_formats
      )
    end

    def create_sampler(label: nil, address_mode_u: :clamp_to_edge, address_mode_v: :clamp_to_edge, address_mode_w: :clamp_to_edge, mag_filter: :nearest, min_filter: :nearest, mipmap_filter: :nearest, lod_min_clamp: 0.0, lod_max_clamp: 32.0, compare: nil, max_anisotropy: 1)
      Sampler.new(self,
        label: label,
        address_mode_u: address_mode_u,
        address_mode_v: address_mode_v,
        address_mode_w: address_mode_w,
        mag_filter: mag_filter,
        min_filter: min_filter,
        mipmap_filter: mipmap_filter,
        lod_min_clamp: lod_min_clamp,
        lod_max_clamp: lod_max_clamp,
        compare: compare,
        max_anisotropy: max_anisotropy
      )
    end

    def create_buffer_with_data(label: nil, data:, usage:, type: :f32)
      data_ptr, byte_size = DataTypes.to_pointer(data, type:)
      DataTypes.validate_alignment!(byte_size, 4, name: "buffer data size")
      buffer = create_buffer(
        label: label,
        size: byte_size,
        usage: usage,
        mapped_at_creation: true
      )
      buffer.mapped_range.write_bytes(data_ptr.read_bytes(byte_size))
      buffer.unmap
      buffer
    end

    def create_query_set(label: nil, type:, count:)
      QuerySet.new(self, label: label, type: type, count: count)
    end

    def create_render_bundle_encoder(color_formats:, depth_stencil_format: nil, sample_count: 1,
                                     depth_read_only: false, stencil_read_only: false, label: nil)
      RenderBundleEncoder.new(self,
        color_formats: color_formats,
        depth_stencil_format: depth_stencil_format,
        sample_count: sample_count,
        depth_read_only: depth_read_only,
        stencil_read_only: stencil_read_only,
        label: label
      )
    end

    def features
      supported = Native::SupportedFeatures.new
      Native.wgpuDeviceGetFeatures(@handle, supported)

      result = []
      if supported[:feature_count] > 0 && !supported[:features].null?
        supported[:features].read_array_of_uint32(supported[:feature_count]).each do |f|
          result << Native::FeatureName[f]
        end
      end
      result
    end

    def has_feature?(feature)
      features.include?(feature)
    end

    def limits
      supported = Native::SupportedLimits.new
      supported[:next_in_chain] = nil
      Native.wgpuDeviceGetLimits(@handle, supported)
      limits_to_hash(supported[:limits])
    end

    def poll(wait: false)
      if Native.device_poll_available?
        Native.wgpuDevicePoll(@handle, wait ? 1 : 0, nil)
      else
        @adapter&.instance&.process_events
        0
      end
    end

    def push_error_scope(filter = :validation)
      filter_value = Native::EnumHelper.coerce(Native::ErrorFilter, filter, name: "error filter")
      Native.wgpuDevicePushErrorScope(@handle, filter_value)
    end

    def pop_error_scope(timeout: nil)
      error_holder = { done: false, status: nil, type: nil, message: nil }

      callback = FFI::Function.new(
        :void, [:uint32, :uint32, Native::StringView.by_value, :pointer, :pointer]
      ) do |status, error_type, message, _userdata1, _userdata2|
        error_holder[:done] = true
        error_holder[:status] = Native::PopErrorScopeStatus[status]
        error_holder[:type] = Native::ErrorType[error_type]
        if message[:data] && !message[:data].null? && message[:length] > 0
          error_holder[:message] = message[:data].read_string(message[:length])
        end
      end

      callback_info = Native::PopErrorScopeCallbackInfo.new
      callback_info[:next_in_chain] = nil
      callback_info[:mode] = AsyncWaiter.callback_mode(instance: @adapter&.instance)
      callback_info[:callback] = callback
      callback_info[:userdata1] = nil
      callback_info[:userdata2] = nil

      callback_token = CallbackKeepalive.retain(self, callback)
      begin
        future = Native.wgpuDevicePopErrorScope(@handle, callback_info)
        AsyncWaiter.wait(
          status_holder: error_holder,
          instance: @adapter&.instance,
          device: self,
          future: future,
          timeout: timeout
        )
      ensure
        CallbackKeepalive.release(self, callback_token)
      end

      error_holder
    end

    # Pops the latest error scope on a background thread.
    #
    # @param timeout [Numeric, nil] maximum wait time in seconds
    # @return [AsyncTask] task whose value is the error hash
    def pop_error_scope_async(timeout: nil)
      AsyncTask.new { pop_error_scope(timeout: timeout) }
    end

    def pop_error_scope_typed(timeout: nil)
      GPUError.from_hash(pop_error_scope(timeout: timeout))
    end

    def with_error_scope(filter = :validation)
      push_error_scope(filter)
      result = yield
      error = GPUError.from_hash(pop_error_scope)
      error&.raise!
      result
    end

    def on_uncaptured_error(&handler)
      raise ArgumentError, "on_uncaptured_error requires a block" unless handler

      set_device_callback(:uncaptured_error, handler)
      self
    end

    def on_device_lost(&handler)
      raise ArgumentError, "on_device_lost requires a block" unless handler

      set_device_callback(:device_lost, handler)
      self
    end

    def destroy
      return if @handle.null?
      Native.wgpuDeviceDestroy(@handle)
    end

    # Releases the default queue, device callbacks, and native device handle.
    #
    # Calling this method more than once has no effect.
    # @return [void]
    def release
      @queue&.release
      return if @handle.null?
      Native.wgpuDeviceRelease(@handle)
      @handle = FFI::Pointer::NULL
      Array(@device_callback_tokens).each { |token| CallbackKeepalive.release(self, token) }
      @device_callback_tokens&.clear
    end

    def self.normalize_required_features(required_features)
      Array(required_features).map do |feature|
        normalize_feature_name(feature)
      end
    end

    def self.normalize_feature_name(feature)
      return feature if feature.is_a?(Integer)

      key = feature.to_s.strip.tr("-", "_").to_sym
      Native::EnumHelper.coerce(Native::FeatureName, key, name: "feature name")
    end

    def self.build_required_limits(adapter, required_limits)
      return nil if required_limits.nil?
      raise ArgumentError, "required_limits must be a Hash" unless required_limits.is_a?(Hash)

      resolved_limits = adapter.limits.dup
      required_limits.each do |name, value|
        key = canonical_limit_key(name)
        resolved_limits[key] = value unless value.nil?
      end

      required = Native::RequiredLimits.new
      required[:next_in_chain] = nil
      LIMIT_FIELDS.each do |field|
        required[:limits][field] = resolved_limits[field] || 0
      end
      required
    end

    def self.canonical_limit_key(name)
      normalized = name.to_s
                       .gsub(/([A-Z])/, "_\\1")
                       .downcase
                       .tr("-", "_")
                       .sub(/^_/, "")
                       .to_sym
      return normalized if LIMIT_FIELDS.include?(normalized)

      raise ArgumentError, "Unknown limit key: #{name}"
    end

    def self.build_uncaptured_error_callback(state)
      FFI::Function.new(
        :void, [:pointer, :uint32, Native::StringView.by_value, :pointer, :pointer]
      ) do |_device, type, message, _userdata1, _userdata2|
        error = GPUError.new(
          type: Native::ErrorType[type] || :unknown,
          message: string_from_callback(message)
        )
        dispatch_device_callback(state, :uncaptured_error, error) do
          warn "Uncaptured GPU error (#{error.type}): #{error.message}"
        end
      end
    end

    def self.build_device_lost_callback(state)
      FFI::Function.new(
        :void, [:pointer, :uint32, Native::StringView.by_value, :pointer, :pointer]
      ) do |_device, reason, message, _userdata1, _userdata2|
        reason_name = Native::DeviceLostReason[reason] || :unknown
        message_text = string_from_callback(message)
        dispatch_device_callback(state, :device_lost, reason_name, message_text) do
          warn "GPU device lost (#{reason_name}): #{message_text}" unless reason_name == :destroyed
        end
      end
    end

    def self.dispatch_device_callback(state, key, *args)
      handler = state[:mutex].synchronize { state[key] }
      handler ? handler.call(*args) : yield
    rescue StandardError => e
      warn "WGPU #{key} handler failed: #{e.class}: #{e.message}"
    end

    def self.string_from_callback(message)
      return "" if message[:data].nil? || message[:data].null? || message[:length].zero?

      message[:data].read_string(message[:length])
    end

    private_class_method :normalize_required_features, :normalize_feature_name,
      :build_required_limits, :canonical_limit_key, :build_uncaptured_error_callback,
      :build_device_lost_callback, :dispatch_device_callback, :string_from_callback

    private

    def retain_device_callback(callback)
      @device_callback_tokens << CallbackKeepalive.retain(self, callback)
    end

    def set_device_callback(name, handler)
      @device_callback_state[:mutex].synchronize { @device_callback_state[name] = handler }
    end

    def limits_to_hash(limits)
      {
        max_texture_dimension_1d: limits[:max_texture_dimension_1d],
        max_texture_dimension_2d: limits[:max_texture_dimension_2d],
        max_texture_dimension_3d: limits[:max_texture_dimension_3d],
        max_texture_array_layers: limits[:max_texture_array_layers],
        max_bind_groups: limits[:max_bind_groups],
        max_bind_groups_plus_vertex_buffers: limits[:max_bind_groups_plus_vertex_buffers],
        max_bindings_per_bind_group: limits[:max_bindings_per_bind_group],
        max_dynamic_uniform_buffers_per_pipeline_layout: limits[:max_dynamic_uniform_buffers_per_pipeline_layout],
        max_dynamic_storage_buffers_per_pipeline_layout: limits[:max_dynamic_storage_buffers_per_pipeline_layout],
        max_sampled_textures_per_shader_stage: limits[:max_sampled_textures_per_shader_stage],
        max_samplers_per_shader_stage: limits[:max_samplers_per_shader_stage],
        max_storage_buffers_per_shader_stage: limits[:max_storage_buffers_per_shader_stage],
        max_storage_textures_per_shader_stage: limits[:max_storage_textures_per_shader_stage],
        max_uniform_buffers_per_shader_stage: limits[:max_uniform_buffers_per_shader_stage],
        max_uniform_buffer_binding_size: limits[:max_uniform_buffer_binding_size],
        max_storage_buffer_binding_size: limits[:max_storage_buffer_binding_size],
        min_uniform_buffer_offset_alignment: limits[:min_uniform_buffer_offset_alignment],
        min_storage_buffer_offset_alignment: limits[:min_storage_buffer_offset_alignment],
        max_vertex_buffers: limits[:max_vertex_buffers],
        max_buffer_size: limits[:max_buffer_size],
        max_vertex_attributes: limits[:max_vertex_attributes],
        max_vertex_buffer_array_stride: limits[:max_vertex_buffer_array_stride],
        max_inter_stage_shader_variables: limits[:max_inter_stage_shader_variables],
        max_color_attachments: limits[:max_color_attachments],
        max_color_attachment_bytes_per_sample: limits[:max_color_attachment_bytes_per_sample],
        max_compute_workgroup_storage_size: limits[:max_compute_workgroup_storage_size],
        max_compute_invocations_per_workgroup: limits[:max_compute_invocations_per_workgroup],
        max_compute_workgroup_size_x: limits[:max_compute_workgroup_size_x],
        max_compute_workgroup_size_y: limits[:max_compute_workgroup_size_y],
        max_compute_workgroup_size_z: limits[:max_compute_workgroup_size_z],
        max_compute_workgroups_per_dimension: limits[:max_compute_workgroups_per_dimension],
        max_subgroup_size: limits[:max_subgroup_size]
      }
    end
  end
end
