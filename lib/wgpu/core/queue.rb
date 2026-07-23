# frozen_string_literal: true

module WGPU
  class Queue
    attr_reader :handle

    def initialize(handle, device: nil)
      @handle = handle
      @device = device
    end

    def submit(command_buffers)
      buffers = Array(command_buffers)
      return if buffers.empty?

      handles = buffers.map(&:handle)
      ptr = FFI::MemoryPointer.new(:pointer, handles.size)
      ptr.write_array_of_pointer(handles)

      Native.wgpuQueueSubmit(@handle, handles.size, ptr)
    end

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

    def read_buffer(buffer, offset: 0, size: nil, device: nil, staging: nil)
      device ||= @device
      raise ArgumentError, "device is required when the queue has no owning device" unless device

      size ||= buffer.size - offset
      owns_staging = staging.nil?
      staging ||= Buffer.new(device, size: size, usage: [:map_read, :copy_dst])
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

      staging.map_sync(:read)
      staging.read_mapped_data(size:)
    ensure
      staging&.unmap if staging && staging.map_state == :mapped
      command_buffer&.release
      encoder&.release
      staging&.release if owns_staging
    end

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
      minimum_bytes_per_row = TextureFormat.bytes_per_row(width, format, aspect:)
      if bytes_per_row < minimum_bytes_per_row
        raise ArgumentError,
          "bytes_per_row must be at least #{minimum_bytes_per_row} for width #{width} and #{format.inspect}"
      end

      rows_per_image = data_layout[:rows_per_image] || height
      buffer_size = bytes_per_row * rows_per_image * depth

      owns_staging = staging.nil?
      staging ||= Buffer.new(device, size: buffer_size, usage: [:map_read, :copy_dst])
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

      staging.map_sync(:read)
      staging.read_mapped_data(size: buffer_size)
    ensure
      staging&.unmap if staging && staging.map_state == :mapped
      command_buffer&.release
      encoder&.release
      staging&.release if owns_staging
    end

    def on_submitted_work_done(device: nil)
      device ||= @device
      instance = device&.adapter&.instance
      status_holder = { done: false, status: nil }

      callback = FFI::Function.new(
        :void, [:uint32, :pointer, :pointer]
      ) do |status, _userdata1, _userdata2|
        status_holder[:done] = true
        status_holder[:status] = Native::QueueWorkDoneStatus[status]
      end

      callback_info = Native::QueueWorkDoneCallbackInfo.new
      callback_info[:next_in_chain] = nil
      callback_info[:mode] = AsyncWaiter.callback_mode(instance: instance)
      callback_info[:callback] = callback
      callback_info[:userdata1] = nil
      callback_info[:userdata2] = nil

      callback_token = CallbackKeepalive.retain(self, callback)
      begin
        future = Native.wgpuQueueOnSubmittedWorkDone(@handle, callback_info)
        AsyncWaiter.wait(status_holder: status_holder, instance: instance, device: device, future: future)
      ensure
        CallbackKeepalive.release(self, callback_token)
      end

      status_holder[:status]
    end

    def on_submitted_work_done_async(device: nil)
      AsyncTask.new do
        on_submitted_work_done(device: device)
      end
    end

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

  end
end
