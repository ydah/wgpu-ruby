# frozen_string_literal: true

module WGPU
  class Buffer
    attr_reader :handle, :size, :usage

    def initialize(device, label: nil, size:, usage:, mapped_at_creation: false)
      @device = device
      @size = size
      @usage = normalize_usage(usage)
      @mapped = mapped_at_creation
      @map_callbacks = []

      desc, keepalive = build_descriptor(
        label:,
        size:,
        usage: @usage,
        mapped_at_creation:
      )
      @descriptor_keepalive = keepalive

      device.push_error_scope(:validation)
      @handle = Native.wgpuDeviceCreateBuffer(device.handle, desc)
      error = device.pop_error_scope
      @descriptor_keepalive = nil

      if @handle.null? || (error[:type] && error[:type] != :no_error)
        msg = error[:message] || "Failed to create buffer"
        raise BufferError, msg
      end
    end

    def write(data, offset: 0)
      ptr, byte_size = data_to_pointer(data)
      Native.wgpuQueueWriteBuffer(@device.queue.handle, @handle, offset, ptr, byte_size)
    end

    def mapped_range(offset: 0, size: nil)
      raise BufferError, "Buffer is not mapped" unless @mapped

      size ||= @size - offset
      ptr = Native.wgpuBufferGetMappedRange(@handle, offset, size)
      raise BufferError, "Failed to get mapped range" if ptr.null?

      BufferMappedRange.new(ptr, size)
    end

    def get_mapped_range(offset: 0, size: nil)
      mapped_range(offset: offset, size: size)
    end

    def unmap
      Native.wgpuBufferUnmap(@handle)
      @mapped = false
    end

    def map_sync(mode, offset: 0, size: nil)
      status_holder, callback, future = begin_map_request(mode, offset: offset, size: size)
      wait_for_map(status_holder, future)
      finalize_map(status_holder)
    ensure
      @map_callbacks.delete(callback) if callback
    end

    def map_async(mode, offset: 0, size: nil)
      status_holder, callback, future = begin_map_request(mode, offset: offset, size: size)
      AsyncTask.new do
        wait_for_map(status_holder, future)
        finalize_map(status_holder)
      ensure
        @map_callbacks.delete(callback)
      end
    end

    def read_mapped_data(offset: 0, size: nil)
      raise BufferError, "Buffer is not mapped" unless @mapped

      size ||= @size - offset
      ptr = Native.wgpuBufferGetConstMappedRange(@handle, offset, size)
      raise BufferError, "Failed to get mapped range" if ptr.null?

      ptr.read_bytes(size)
    end

    def read_mapped(offset: 0, size: nil)
      read_mapped_data(offset: offset, size: size)
    end

    def write_mapped(data, offset: 0)
      raise BufferError, "Buffer is not mapped" unless @mapped

      ptr, byte_size = data_to_pointer(data)
      target = Native.wgpuBufferGetMappedRange(@handle, offset, byte_size)
      raise BufferError, "Failed to get mapped range" if target.null?

      target.put_bytes(0, ptr.read_bytes(byte_size))
    end

    def read_mapped_floats(offset: 0, count: nil)
      raise BufferError, "Buffer is not mapped" unless @mapped

      size = count ? count * 4 : @size - offset
      ptr = Native.wgpuBufferGetConstMappedRange(@handle, offset, size)
      raise BufferError, "Failed to get mapped range" if ptr.null?

      ptr.read_array_of_float(size / 4)
    end

    def map_state
      state = Native.wgpuBufferGetMapState(@handle)
      state || (@mapped ? :mapped : :unmapped)
    end

    def destroy
      Native.wgpuBufferDestroy(@handle)
    end

    def release
      return if @handle.null?
      Native.wgpuBufferRelease(@handle)
      @handle = FFI::Pointer::NULL
    end

    private

    def build_descriptor(label:, size:, usage:, mapped_at_creation:)
      keepalive = []
      desc = Native::BufferDescriptor.new
      desc[:next_in_chain] = nil
      DescriptorHelpers.set_label(desc, label, keepalive:)
      desc[:usage] = usage
      desc[:size] = size
      desc[:mapped_at_creation] = mapped_at_creation ? 1 : 0
      [desc, keepalive]
    end

    def begin_map_request(mode, offset:, size:)
      size ||= @size - offset
      mode_flag = Native::EnumHelper.coerce(Native::MapMode, mode, name: "map mode")

      status_holder = { done: false, status: nil, message: nil }
      callback = FFI::Function.new(:void, [:uint32, Native::StringView.by_value, :pointer, :pointer]) do |status, message, _userdata1, _userdata2|
        status_holder[:done] = true
        status_holder[:status] = Native::MapAsyncStatus[status]
        if message[:data] && !message[:data].null? && message[:length] > 0
          status_holder[:message] = message[:data].read_string(message[:length])
        end
      end
      @map_callbacks << callback

      callback_info = Native::BufferMapCallbackInfo.new
      callback_info[:next_in_chain] = nil
      callback_info[:mode] = AsyncWaiter.callback_mode(instance: @device.adapter&.instance)
      callback_info[:callback] = callback
      callback_info[:userdata1] = nil
      callback_info[:userdata2] = nil

      future = Native.wgpuBufferMapAsync(@handle, mode_flag, offset, size, callback_info)

      [status_holder, callback, future]
    end

    def wait_for_map(status_holder, future)
      AsyncWaiter.wait(
        status_holder: status_holder,
        instance: @device.adapter&.instance,
        device: @device,
        future: future
      )
    end

    def finalize_map(status_holder)
      if status_holder[:status] == :success
        @mapped = true
        true
      else
        detail = status_holder[:message]
        base = "Failed to map buffer: #{status_holder[:status]}"
        raise BufferError, detail && !detail.empty? ? "#{base} (#{detail})" : base
      end
    end

    def normalize_usage(usage)
      Native::EnumHelper.coerce_flags(Native::BufferUsage, usage, name: "buffer usage")
    end

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

  class BufferMappedRange
    def initialize(pointer, size)
      @pointer = pointer
      @size = size
    end

    def read_floats(count = nil)
      count ||= @size / 4
      @pointer.read_array_of_float(count)
    end

    def write_floats(data)
      @pointer.write_array_of_float(data)
    end

    def read_bytes
      @pointer.read_bytes(@size)
    end

    def write_bytes(data)
      @pointer.put_bytes(0, data)
    end
  end
end
