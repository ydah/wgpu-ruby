# frozen_string_literal: true

module WGPU
  class Queue
    attr_reader :handle

    # Wraps a device's native submission queue.
    # @param handle [FFI::Pointer] native queue handle
    # @param device [Device, nil] owning device
    def initialize(handle, device: nil)
      @handle = handle
      @device = device
    end

    # Submits command buffers exactly once in the supplied order.
    # @param command_buffers [CommandBuffer, Array<CommandBuffer>] buffers to submit
    # @return [void]
    # @raise [CommandError] for duplicate or previously submitted buffers
    def submit(command_buffers)
      buffers = Array(command_buffers)
      return if buffers.empty?

      if buffers.map(&:object_id).uniq.length != buffers.length
        raise CommandError, "The same command buffer cannot appear twice in one submission"
      end
      buffers.each do |buffer|
        raise CommandError, "Command buffer has already been submitted" if buffer.submitted?
      end

      handles = buffers.map(&:handle)
      ptr = FFI::MemoryPointer.new(:pointer, handles.size)
      ptr.write_array_of_pointer(handles)

      Native.wgpuQueueSubmit(@handle, handles.size, ptr)
      buffers.each(&:mark_submitted!)
    end

    # Writes typed data into a GPU buffer.
    # @param buffer [Buffer] destination buffer
    # @param buffer_offset [Integer] destination byte offset
    # @param data [Array, String, FFI::Pointer] source data
    # @return [void]
    def write_buffer(buffer, buffer_offset, data, data_offset: 0, size: nil, type: :f32)
      data_ptr, byte_size = DataTypes.to_pointer(data, type:)
      DataTypes.validate_alignment!(buffer_offset, 4, name: "buffer_offset")
      data_offset = Integer(data_offset)
      raise ArgumentError, "data_offset must be non-negative" if data_offset.negative?
      raise ArgumentError, "data_offset out of range" if data_offset > byte_size

      write_size = size.nil? ? (byte_size - data_offset) : Integer(size)
      raise ArgumentError, "size must be non-negative" if write_size.negative?
      raise ArgumentError, "data_offset + size out of range" if data_offset + write_size > byte_size
      DataTypes.validate_alignment!(write_size, 4, name: "size")

      Native.wgpuQueueWriteBuffer(
        @handle,
        buffer.handle,
        buffer_offset,
        data_ptr + data_offset,
        write_size
      )
    end

    # Writes typed data into a texture region.
    # @param destination [Hash] destination texture and origin
    # @param data [Array, String, FFI::Pointer] source data
    # @param data_layout [Hash] source byte layout
    # @param size [Hash, Array] extent to write
    # @return [void]
    def write_texture(destination:, data:, data_layout:, size:, type: :f32)
      data_ptr, byte_size = DataTypes.to_pointer(data, type:)

      dst = Native::ImageCopyTexture.new
      dst[:texture] = destination[:texture].handle
      dst[:mip_level] = destination[:mip_level] || 0
      dst[:origin][:x] = destination.dig(:origin, :x) || 0
      dst[:origin][:y] = destination.dig(:origin, :y) || 0
      dst[:origin][:z] = destination.dig(:origin, :z) || 0
      dst[:aspect] = Native::EnumHelper.coerce(
        Native::TextureAspect,
        destination[:aspect] || :all,
        name: "texture aspect"
      )

      extent = Native::Extent3D.new
      if size.is_a?(Array)
        extent[:width] = size[0]
        extent[:height] = size[1] || 1
        extent[:depth_or_array_layers] = size[2] || 1
      else
        extent[:width] = size[:width]
        extent[:height] = size[:height] || 1
        extent[:depth_or_array_layers] = size[:depth_or_array_layers] || 1
      end

      layout = Native::TextureDataLayout.new
      layout[:offset] = data_layout[:offset] || 0
      layout[:bytes_per_row] = data_layout[:bytes_per_row]
      layout[:rows_per_image] = data_layout[:rows_per_image] || extent[:height]

      Native.wgpuQueueWriteTexture(@handle, dst, data_ptr, byte_size, layout, extent)
    end

    # Copies a GPU buffer to mapped staging memory and returns its bytes.
    # @param buffer [Buffer] source buffer
    # @param staging [Buffer, nil] reusable map-read staging buffer
    # @return [String] copied bytes
    def read_buffer(buffer, offset: 0, size: nil, device: nil, staging: nil)
      device ||= @device
      raise ArgumentError, "device is required when the queue has no owning device" unless device

      size ||= buffer.size - offset
      owns_staging = staging.nil?
      staging ||= Buffer.new(device, size: size, usage: [:map_read, :copy_dst])
      validate_readback_staging!(staging, size)
      encoder = CommandEncoder.new(device)
      encoder.copy_buffer_to_buffer(
        source: buffer,
        source_offset: offset,
        destination: staging,
        destination_offset: 0,
        size: size
      )
      command_buffer = encoder.finish
      submit([command_buffer])

      map_requested = true
      staging.map_sync(:read)
      staging.read_mapped_data(size:)
    ensure
      cleanup_readback_resources(
        staging:,
        unmap_staging: map_requested,
        owns_staging:,
        command_buffer:,
        encoder:,
        active_error: $!
      )
    end

    # Copies a texture region to mapped staging memory and returns its padded bytes.
    # @param source [Hash] source texture, origin, aspect, and optional format
    # @param data_layout [Hash] destination byte layout
    # @param size [Hash, Array] extent to read
    # @param staging [Buffer, nil] reusable map-read staging buffer
    # @return [String] copied bytes
    def read_texture(source:, data_layout:, size:, device: nil, staging: nil)
      device ||= @device
      raise ArgumentError, "device is required when the queue has no owning device" unless device

      width, height, depth = texture_extent(size)
      bytes_per_row = data_layout[:bytes_per_row]
      raise ArgumentError, "data_layout[:bytes_per_row] is required" unless bytes_per_row

      DataTypes.validate_alignment!(
        bytes_per_row,
        TextureFormat::COPY_ALIGNMENT,
        name: "bytes_per_row"
      )
      format = source[:format] || source[:texture].format
      aspect = source[:aspect] || :all
      tight_bytes_per_row = TextureFormat.bytes_per_row(width, format, aspect:)
      minimum_bytes_per_row = TextureFormat.aligned_bytes_per_row(width, format, aspect:)
      if bytes_per_row < minimum_bytes_per_row
        raise ArgumentError,
          "bytes_per_row must be at least #{minimum_bytes_per_row} for width #{width} and #{format.inspect} " \
          "(tight row is #{tight_bytes_per_row} bytes)"
      end

      rows_per_image = data_layout[:rows_per_image] || height
      buffer_size = bytes_per_row * rows_per_image * depth

      owns_staging = staging.nil?
      staging ||= Buffer.new(device, size: buffer_size, usage: [:map_read, :copy_dst])
      validate_readback_staging!(staging, buffer_size)
      encoder = CommandEncoder.new(device)
      encoder.copy_texture_to_buffer(
        source: source,
        destination: {
          buffer: staging,
          offset: 0,
          bytes_per_row: bytes_per_row,
          rows_per_image: rows_per_image
        },
        copy_size: size
      )
      command_buffer = encoder.finish
      submit([command_buffer])

      map_requested = true
      staging.map_sync(:read)
      staging.read_mapped_data(size: buffer_size)
    ensure
      cleanup_readback_resources(
        staging:,
        unmap_staging: map_requested,
        owns_staging:,
        command_buffer:,
        encoder:,
        active_error: $!
      )
    end

    # Waits until all previously submitted queue work completes.
    # @param device [Device, nil] device used to drive callback progress
    # @param timeout [Numeric, nil] maximum wait time in seconds
    # @return [Symbol] native completion status
    def on_submitted_work_done(device: nil, timeout: nil)
      device ||= @device
      instance = device&.adapter&.instance
      status_holder = { done: false, status: nil }

      callback_token = nil
      callback = FFI::Function.new(
        :void, [:uint32, :pointer, :pointer]
      ) do |status, _userdata1, _userdata2|
        begin
          status_holder[:status] = Native::QueueWorkDoneStatus[status]
          status_holder[:done] = true
        ensure
          CallbackKeepalive.release(self, callback_token)
        end
      end

      callback_info = Native::QueueWorkDoneCallbackInfo.new
      callback_info[:next_in_chain] = nil
      callback_info[:mode] = AsyncWaiter.callback_mode(instance: instance)
      callback_info[:callback] = callback
      callback_info[:userdata1] = nil
      callback_info[:userdata2] = nil

      callback_token = CallbackKeepalive.retain(self, callback)
      future =
        begin
          Native.wgpuQueueOnSubmittedWorkDone(@handle, callback_info)
        rescue StandardError
          CallbackKeepalive.release(self, callback_token)
          raise
        end
      AsyncWaiter.wait(
        status_holder: status_holder,
        instance: instance,
        device: device,
        future: future,
        timeout: timeout
      )

      status_holder[:status]
    end

    # Waits for prior queue work on a background task.
    # @return [AsyncTask] task yielding the native completion status
    def on_submitted_work_done_async(device: nil, timeout: nil)
      AsyncTask.new do
        on_submitted_work_done(device: device, timeout: timeout)
      end
    end

    # Releases the native queue handle.
    #
    # Calling this method more than once has no effect.
    # @return [void]
    def release
      return if @handle.null?
      Native.wgpuQueueRelease(@handle)
      @handle = FFI::Pointer::NULL
    end

    private

    def texture_extent(size)
      if size.is_a?(Array)
        [size.fetch(0), size[1] || 1, size[2] || 1]
      else
        [size.fetch(:width), size[:height] || 1, size[:depth_or_array_layers] || 1]
      end
    end

    def validate_readback_staging!(staging, required_size)
      if staging.size < required_size
        raise ArgumentError,
          "staging buffer size must be at least #{required_size} bytes (got #{staging.size})"
      end

      required_usage = Native::BufferUsage.fetch(:map_read) | Native::BufferUsage.fetch(:copy_dst)
      unless (staging.usage & required_usage) == required_usage
        raise ArgumentError, "staging buffer usage must include :map_read and :copy_dst"
      end

      return if staging.map_state == :unmapped

      raise ArgumentError, "staging buffer must be unmapped before readback"
    end

    def cleanup_readback_resources(
      staging:,
      unmap_staging:,
      owns_staging:,
      command_buffer:,
      encoder:,
      active_error:
    )
      cleanup_error = nil

      begin
        staging&.unmap if unmap_staging && staging && staging.map_state == :mapped
      rescue StandardError => e
        cleanup_error ||= e
      ensure
        begin
          command_buffer&.release
        rescue StandardError => e
          cleanup_error ||= e
        ensure
          begin
            encoder&.release
          rescue StandardError => e
            cleanup_error ||= e
          ensure
            begin
              staging&.release if owns_staging
            rescue StandardError => e
              cleanup_error ||= e
            end
          end
        end
      end

      raise cleanup_error if cleanup_error && active_error.nil?
    end

  end
end
