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

    def write_buffer(buffer, buffer_offset, data, data_offset: 0, size: nil)
      data_ptr, byte_size = data_to_pointer(data)
      data_offset = Integer(data_offset)
      raise ArgumentError, "data_offset must be non-negative" if data_offset.negative?
      raise ArgumentError, "data_offset out of range" if data_offset > byte_size

      write_size = size.nil? ? (byte_size - data_offset) : Integer(size)
      raise ArgumentError, "size must be non-negative" if write_size.negative?
      raise ArgumentError, "data_offset + size out of range" if data_offset + write_size > byte_size

      Native.wgpuQueueWriteBuffer(
        @handle,
        buffer.handle,
        buffer_offset,
        data_ptr + data_offset,
        write_size
      )
    end

    def write_texture(destination:, data:, data_layout:, size:)
      data_ptr, byte_size = data_to_pointer(data)

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

    def read_buffer(buffer, offset: 0, size: nil, device:)
      size ||= buffer.size - offset

      staging = Buffer.new(device,
        size: size,
        usage: [:map_read, :copy_dst]
      )

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
      data = staging.read_mapped_data
      staging.unmap
      staging.release

      data
    end

    def read_texture(source:, data_layout:, size:, device:)
      height = size[:height] || size[1] || 1
      depth = size[:depth_or_array_layers] || size[2] || 1
      bytes_per_row = data_layout[:bytes_per_row]
      rows_per_image = data_layout[:rows_per_image] || height
      buffer_size = bytes_per_row * rows_per_image * depth

      staging = Buffer.new(device,
        size: buffer_size,
        usage: [:map_read, :copy_dst]
      )

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
      data = staging.read_mapped_data
      staging.unmap
      staging.release

      data
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

      future = Native.wgpuQueueOnSubmittedWorkDone(@handle, callback_info)
      AsyncWaiter.wait(status_holder: status_holder, instance: instance, device: device, future: future)

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

    def data_to_pointer(data)
      case data
      when String
        ptr = FFI::MemoryPointer.new(:char, data.bytesize)
        ptr.put_bytes(0, data)
        [ptr, data.bytesize]
      when Array
        ptr = FFI::MemoryPointer.new(:float, data.size)
        ptr.write_array_of_float(data)
        [ptr, data.size * 4]
      when FFI::Pointer
        [data, data.size]
      else
        raise ArgumentError, "Unsupported data type: #{data.class}"
      end
    end
  end
end
