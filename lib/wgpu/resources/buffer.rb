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

      desc = Native::BufferDescriptor.new
      desc[:next_in_chain] = nil
      if label
        label_ptr = FFI::MemoryPointer.from_string(label)
        desc[:label][:data] = label_ptr
        desc[:label][:length] = label.bytesize
      else
        desc[:label][:data] = nil
        desc[:label][:length] = 0
      end
      desc[:usage] = @usage
      desc[:size] = size
      desc[:mapped_at_creation] = mapped_at_creation ? 1 : 0

      device.push_error_scope(:validation)
      @handle = Native.wgpuDeviceCreateBuffer(device.handle, desc)
      error = device.pop_error_scope

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
      status_holder, callback = begin_map_request(mode, offset: offset, size: size)
      wait_for_map(status_holder)
      finalize_map(status_holder)
    ensure
      @map_callbacks.delete(callback) if callback
    end

    def map_async(mode, offset: 0, size: nil)
      status_holder, callback = begin_map_request(mode, offset: offset, size: size)
      AsyncTask.new do
        wait_for_map(status_holder)
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

    def begin_map_request(mode, offset:, size:)
      size ||= @size - offset
      mode_flag = case mode
                  when :read then Native::MapMode[:read]
                  when :write then Native::MapMode[:write]
                  when Integer then mode
                  else raise ArgumentError, "Invalid map mode: #{mode}"
                  end

      status_holder = { done: false, status: nil }
      callback = FFI::Function.new(:void, [:uint32, :pointer]) do |status, _userdata|
        status_holder[:done] = true
        status_holder[:status] = Native::MapAsyncStatus[status]
      end
      @map_callbacks << callback

      callback_info = Native::BufferMapCallbackInfo.new
      callback_info[:next_in_chain] = nil
      callback_info[:mode] = 1
      callback_info[:callback] = callback
      callback_info[:userdata] = nil

      Native.wgpuBufferMapAsync(@handle, mode_flag, offset, size, callback_info)

      [status_holder, callback]
    end

    def wait_for_map(status_holder)
      until status_holder[:done]
        Native.wgpuDevicePoll(@device.handle, 0, nil)
        sleep(0.001)
      end
    end

    def finalize_map(status_holder)
      if status_holder[:status] == :success
        @mapped = true
        true
      else
        raise BufferError, "Failed to map buffer: #{status_holder[:status]}"
      end
    end

    def normalize_usage(usage)
      case usage
      when Integer
        usage
      when Symbol
        Native::BufferUsage[usage]
      when Array
        usage.reduce(0) { |acc, u| acc | Native::BufferUsage[u] }
      else
        raise ArgumentError, "Invalid usage type: #{usage.class}"
      end
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
