# frozen_string_literal: true

module WGPU
  class Buffer
    attr_reader :handle, :size, :usage

    # Creates a GPU buffer with the requested size and usage.
    # @param device [Device] owning device
    # @param size [Integer] buffer size in bytes
    # @param usage [Symbol, Array<Symbol>, Integer] usage flags
    # @param mapped_at_creation [Boolean] whether to expose an initial mapped range
    # @raise [BufferError] if native validation or creation fails
    def initialize(device, label: nil, size:, usage:, mapped_at_creation: false)
      @device = device
      @size = size
      @usage =
        begin
          normalize_usage(usage)
        rescue ArgumentError => e
          raise ArgumentError, buffer_error_message(e.message, label)
        end
      @mapped = mapped_at_creation
      @map_state = mapped_at_creation ? :mapped : :unmapped
      @map_generation = 0
      @map_state_mutex = Mutex.new

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
        raise BufferError, buffer_error_message(msg, label)
      end
    end

    # Writes typed data through the device's default queue.
    # @param data [Array, String, FFI::Pointer] source data
    # @param offset [Integer] destination byte offset
    # @param type [Symbol] source element type
    # @return [void]
    def write(data, offset: 0, type: :f32)
      ptr, byte_size = DataTypes.to_pointer(data, type:)
      DataTypes.validate_alignment!(offset, 4, name: "offset")
      DataTypes.validate_alignment!(byte_size, 4, name: "data size")
      Native.wgpuQueueWriteBuffer(@device.queue.handle, @handle, offset, ptr, byte_size)
    end

    # Returns a writable view of a mapped byte range.
    # @return [BufferMappedRange]
    # @raise [BufferError] if the buffer is not mapped or no range is available
    def mapped_range(offset: 0, size: nil)
      raise BufferError, "Buffer is not mapped" unless @mapped

      size ||= @size - offset
      offset, size = validate_map_range!(offset, size)
      ptr = Native.wgpuBufferGetMappedRange(@handle, offset, size)
      raise BufferError, "Failed to get mapped range" if ptr.null?

      BufferMappedRange.new(ptr, size)
    end

    # Returns a writable view of a mapped byte range.
    # @return [BufferMappedRange]
    def get_mapped_range(offset: 0, size: nil)
      mapped_range(offset: offset, size: size)
    end

    # Unmaps the buffer and invalidates its mapped ranges.
    # @return [void]
    def unmap
      Native.wgpuBufferUnmap(@handle)
      map_state_mutex.synchronize do
        @map_generation = current_map_generation + 1
        @mapped = false
        @map_state = :unmapped
      end
    end

    # Maps a range and waits for native completion.
    # @param mode [Symbol, Integer] map access mode
    # @param timeout [Numeric, nil] maximum wait time in seconds
    # @return [Boolean] true when mapped
    # @raise [BufferError] if mapping fails
    def map_sync(mode, offset: 0, size: nil, timeout: nil)
      status_holder, _callback_token, future, generation =
        begin_map_request(mode, offset: offset, size: size)
      wait_for_map(status_holder, future, timeout:)
      finalize_map(status_holder, generation)
    end

    # Maps a range on a background task.
    # @param mode [Symbol, Integer] map access mode
    # @return [AsyncTask] task yielding true when mapped
    def map_async(mode, offset: 0, size: nil)
      status_holder, _callback_token, future, generation =
        begin_map_request(mode, offset: offset, size: size)
      AsyncTask.new do
        wait_for_map(status_holder, future)
        finalize_map(status_holder, generation)
      end
    end

    # Copies bytes from a const mapped range.
    # @return [String] mapped bytes
    # @raise [BufferError] if the buffer is not mapped
    def read_mapped_data(offset: 0, size: nil)
      raise BufferError, "Buffer is not mapped" unless @mapped

      size ||= @size - offset
      offset, size = validate_map_range!(offset, size)
      ptr = Native.wgpuBufferGetConstMappedRange(@handle, offset, size)
      raise BufferError, "Failed to get mapped range" if ptr.null?

      ptr.read_bytes(size)
    end

    # Reads mapped bytes, optionally decoding typed values.
    # @param type [Symbol, nil] element type, or +nil+ for raw bytes
    # @return [String, Array]
    def read_mapped(offset: 0, size: nil, type: nil)
      bytes = read_mapped_data(offset: offset, size: size)
      type ? DataTypes.unpack(bytes, type:) : bytes
    end

    # Writes typed data into a mapped range.
    # @param data [Array, String, FFI::Pointer] source data
    # @param type [Symbol] source element type
    # @return [void]
    def write_mapped(data, offset: 0, type: :f32)
      raise BufferError, "Buffer is not mapped" unless @mapped

      ptr, byte_size = DataTypes.to_pointer(data, type:)
      offset, byte_size = validate_map_range!(offset, byte_size)
      target = Native.wgpuBufferGetMappedRange(@handle, offset, byte_size)
      raise BufferError, "Failed to get mapped range" if target.null?

      target.put_bytes(0, ptr.read_bytes(byte_size))
    end

    # Reads mapped bytes as 32-bit floating-point values.
    #
    # @param offset [Integer] byte offset in the buffer
    # @param count [Integer, nil] values to read; defaults to the remaining range
    # @return [Array<Float>] decoded values
    # @raise [BufferError] if the buffer is not mapped
    def read_mapped_floats(offset: 0, count: nil)
      read_mapped_values(type: :f32, offset:, count:)
    end

    # Reads mapped bytes as unsigned 32-bit integers.
    #
    # @param offset [Integer] byte offset in the buffer
    # @param count [Integer, nil] values to read; defaults to the remaining range
    # @return [Array<Integer>] decoded values
    # @raise [BufferError] if the buffer is not mapped
    def read_mapped_uint32s(offset: 0, count: nil)
      read_mapped_values(type: :u32, offset:, count:)
    end

    # Reads mapped bytes as signed 32-bit integers.
    #
    # @param offset [Integer] byte offset in the buffer
    # @param count [Integer, nil] values to read; defaults to the remaining range
    # @return [Array<Integer>] decoded values
    # @raise [BufferError] if the buffer is not mapped
    def read_mapped_int32s(offset: 0, count: nil)
      read_mapped_values(type: :i32, offset:, count:)
    end

    # Reads mapped bytes as 64-bit floating-point values.
    #
    # @param offset [Integer] byte offset in the buffer
    # @param count [Integer, nil] values to read; defaults to the remaining range
    # @return [Array<Float>] decoded values
    # @raise [BufferError] if the buffer is not mapped
    def read_mapped_float64s(offset: 0, count: nil)
      read_mapped_values(type: :f64, offset:, count:)
    end

    # Reads mapped bytes as unsigned 16-bit integers.
    #
    # @param offset [Integer] byte offset in the buffer
    # @param count [Integer, nil] values to read; defaults to the remaining range
    # @return [Array<Integer>] decoded values
    # @raise [BufferError] if the buffer is not mapped
    def read_mapped_uint16s(offset: 0, count: nil)
      read_mapped_values(type: :u16, offset:, count:)
    end

    # Reads mapped bytes as unsigned 8-bit integers.
    #
    # @param offset [Integer] byte offset in the buffer
    # @param count [Integer, nil] values to read; defaults to the remaining range
    # @return [Array<Integer>] decoded values
    # @raise [BufferError] if the buffer is not mapped
    def read_mapped_uint8s(offset: 0, count: nil)
      read_mapped_values(type: :u8, offset:, count:)
    end

    # Reads mapped values of the requested element type.
    # @param type [Symbol] element type
    # @param count [Integer, nil] number of values
    # @return [Array]
    def read_mapped_values(type: :f32, offset: 0, count: nil)
      element_size = DataTypes.byte_size(type)
      size = count ? count * element_size : @size - offset
      DataTypes.unpack(read_mapped_data(offset:, size:), type:)
    end

    # Returns the current mapping state.
    # @return [Symbol]
    def map_state
      return map_state_mutex.synchronize { @map_state } unless Native.buffer_map_state_available?

      Native.wgpuBufferGetMapState(@handle) || map_state_mutex.synchronize { @map_state }
    end

    # Destroys the buffer's storage.
    # @return [void]
    def destroy
      Native.wgpuBufferDestroy(@handle)
      invalidate_map_state
    end

    # Releases the native buffer handle.
    #
    # Calling this method more than once has no effect.
    # @return [void]
    def release
      return if @handle.null?
      Native.wgpuBufferRelease(@handle)
      @handle = FFI::Pointer::NULL
      invalidate_map_state
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
      offset, size = validate_map_range!(offset, size)
      mode_flag = Native::EnumHelper.coerce(Native::MapMode, mode, name: "map mode")

      status_holder = { done: false, status: nil, message: nil }
      generation = map_state_mutex.synchronize do
        @map_generation = current_map_generation + 1
        @map_state = :pending
        @map_generation
      end
      callback_lifetime_release = device_callback_lifetime_lease
      callback_token = nil
      callback = FFI::Function.new(:void, [:uint32, Native::StringView.by_value, :pointer, :pointer]) do |status, message, _userdata1, _userdata2|
        begin
          status_holder[:status] = Native::MapAsyncStatus[status]
          if message[:data] && !message[:data].null? && message[:length] > 0
            status_holder[:message] = message[:data].read_string(message[:length])
          end
          map_state_mutex.synchronize do
            if generation == current_map_generation && !@handle.null?
              @mapped = status_holder[:status] == :success
              @map_state = @mapped ? :mapped : :unmapped
            end
          end
          status_holder[:done] = true
        ensure
          CallbackKeepalive.release(self, callback_token)
          callback_lifetime_release.call
        end
      end
      callback_token = CallbackKeepalive.retain(self, callback)

      callback_info = Native::BufferMapCallbackInfo.new
      callback_info[:next_in_chain] = nil
      callback_info[:mode] = AsyncWaiter.callback_mode(instance: @device.adapter&.instance)
      callback_info[:callback] = callback
      callback_info[:userdata1] = nil
      callback_info[:userdata2] = nil

      future =
        begin
          Native.wgpuBufferMapAsync(@handle, mode_flag, offset, size, callback_info)
        rescue StandardError
          CallbackKeepalive.release(self, callback_token)
          callback_lifetime_release.call
          invalidate_map_state(generation)
          raise
        end

      [status_holder, callback_token, future, generation]
    end

    def wait_for_map(status_holder, future, timeout: nil)
      AsyncWaiter.wait(
        status_holder: status_holder,
        instance: @device.adapter&.instance,
        device: @device,
        future: future,
        timeout: timeout
      )
    end

    def finalize_map(status_holder, generation)
      if status_holder[:status] == :success
        map_state_mutex.synchronize do
          if generation == current_map_generation && !@handle.null?
            @mapped = true
            @map_state = :mapped
          end
        end
        true
      else
        invalidate_map_state(generation)
        detail = status_holder[:message]
        base = "Failed to map buffer: #{status_holder[:status]}"
        raise BufferError, detail && !detail.empty? ? "#{base} (#{detail})" : base
      end
    end

    def invalidate_map_state(generation = nil)
      map_state_mutex.synchronize do
        return if generation && generation != current_map_generation

        @map_generation = current_map_generation + 1
        @mapped = false
        @map_state = :unmapped
      end
    end

    def current_map_generation
      @map_generation ||= 0
    end

    def map_state_mutex
      @map_state_mutex ||= Mutex.new
    end

    def normalize_usage(usage)
      Native::EnumHelper.coerce_flags(Native::BufferUsage, usage, name: "buffer usage")
    end

    def buffer_error_message(message, label)
      context = label ? " #{label.inspect}" : ""
      "create buffer#{context}: #{message}"
    end

    def validate_map_range!(offset, size)
      offset = DataTypes.validate_alignment!(offset, 8, name: "map offset")
      size = DataTypes.validate_alignment!(size, 4, name: "map size")
      if offset > @size || size > @size - offset
        raise ArgumentError,
          "mapped range (offset #{offset}, size #{size}) exceeds buffer size #{@size}"
      end

      [offset, size]
    end
  end

  class BufferMappedRange
    # Wraps a native mapped memory range.
    # @param pointer [FFI::Pointer] start of mapped memory
    # @param size [Integer] range size in bytes
    def initialize(pointer, size)
      @pointer = pointer
      @size = size
    end

    # Reads 32-bit floating-point values from the mapped range.
    #
    # @param count [Integer, nil] values to read; defaults to the full range
    # @return [Array<Float>] decoded values
    def read_floats(count = nil)
      read(type: :f32, count:)
    end

    # Writes 32-bit floating-point values into the mapped range.
    #
    # @param data [Array<Numeric>] values to write
    # @return [void]
    # @raise [ArgumentError] if the data exceeds the mapped range
    def write_floats(data)
      write(data, type: :f32)
    end

    # Reads unsigned 32-bit integers from the mapped range.
    #
    # @param count [Integer, nil] values to read; defaults to the full range
    # @return [Array<Integer>] decoded values
    def read_uint32s(count = nil)
      read(type: :u32, count:)
    end

    # Writes unsigned 32-bit integers into the mapped range.
    #
    # @param data [Array<Integer>] values to write
    # @return [void]
    # @raise [ArgumentError] if the data exceeds the mapped range
    def write_uint32s(data)
      write(data, type: :u32)
    end

    # Reads signed 32-bit integers from the mapped range.
    #
    # @param count [Integer, nil] values to read; defaults to the full range
    # @return [Array<Integer>] decoded values
    def read_int32s(count = nil)
      read(type: :i32, count:)
    end

    # Writes signed 32-bit integers into the mapped range.
    #
    # @param data [Array<Integer>] values to write
    # @return [void]
    # @raise [ArgumentError] if the data exceeds the mapped range
    def write_int32s(data)
      write(data, type: :i32)
    end

    # Reads 64-bit floating-point values from the mapped range.
    #
    # @param count [Integer, nil] values to read; defaults to the full range
    # @return [Array<Float>] decoded values
    def read_float64s(count = nil)
      read(type: :f64, count:)
    end

    # Writes 64-bit floating-point values into the mapped range.
    #
    # @param data [Array<Numeric>] values to write
    # @return [void]
    # @raise [ArgumentError] if the data exceeds the mapped range
    def write_float64s(data)
      write(data, type: :f64)
    end

    # Reads unsigned 16-bit integers from the mapped range.
    #
    # @param count [Integer, nil] values to read; defaults to the full range
    # @return [Array<Integer>] decoded values
    def read_uint16s(count = nil)
      read(type: :u16, count:)
    end

    # Writes unsigned 16-bit integers into the mapped range.
    #
    # @param data [Array<Integer>] values to write
    # @return [void]
    # @raise [ArgumentError] if the data exceeds the mapped range
    def write_uint16s(data)
      write(data, type: :u16)
    end

    # Reads unsigned 8-bit integers from the mapped range.
    #
    # @param count [Integer, nil] values to read; defaults to the full range
    # @return [Array<Integer>] decoded values
    def read_uint8s(count = nil)
      read(type: :u8, count:)
    end

    # Writes unsigned 8-bit integers into the mapped range.
    #
    # @param data [Array<Integer>] values to write
    # @return [void]
    # @raise [ArgumentError] if the data exceeds the mapped range
    def write_uint8s(data)
      write(data, type: :u8)
    end

    # Decodes typed values from the mapped range.
    # @param type [Symbol] element type
    # @param count [Integer, nil] number of values
    # @return [Array]
    def read(type: :f32, count: nil)
      byte_size = DataTypes.byte_size(type)
      count ||= @size / byte_size
      count = Integer(count)
      raise ArgumentError, "count must be non-negative" if count.negative?

      bytes_to_read = count * byte_size
      validate_byte_length!(bytes_to_read)
      DataTypes.unpack(@pointer.read_bytes(bytes_to_read), type:)
    end

    # Encodes typed values into the mapped range.
    # @param data [Array, String] values or bytes to write
    # @param type [Symbol] element type
    # @return [void]
    # @raise [ArgumentError] if the encoded data exceeds the range
    def write(data, type: :f32)
      bytes = data.is_a?(String) ? data : DataTypes.pack(data, type:)
      raise ArgumentError, "data exceeds mapped range" if bytes.bytesize > @size

      @pointer.put_bytes(0, bytes)
    end

    # Returns all bytes in the mapped range.
    # @return [String]
    def read_bytes
      @pointer.read_bytes(@size)
    end

    # Writes bytes at the start of the mapped range.
    # @param data [String] bytes to write
    # @return [void]
    def write_bytes(data)
      validate_byte_length!(data.bytesize)
      @pointer.put_bytes(0, data)
    end

    private

    def validate_byte_length!(byte_length)
      return if byte_length <= @size

      raise ArgumentError, "data exceeds mapped range"
    end
  end
end
