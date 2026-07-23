# frozen_string_literal: true

module WGPU
  class QuerySet
    attr_reader :handle, :count, :type

    # Creates a set of GPU queries.
    # @param device [Device] owning device
    # @param type [Symbol, Integer] query type
    # @param count [Integer] number of queries
    # @raise [ResourceError] if native creation fails
    def initialize(device, label: nil, type:, count:)
      @device = device
      @count = Integer(count)
      type_value = Native::EnumHelper.coerce(Native::QueryType, type, name: "query type")
      @type = Native::QueryType[type_value]
      @destroyed = false

      desc = Native::QuerySetDescriptor.new
      desc[:next_in_chain] = nil
      if label
        @label_ptr = FFI::MemoryPointer.from_string(label)
        desc[:label][:data] = @label_ptr
        desc[:label][:length] = label.bytesize
      else
        desc[:label][:data] = nil
        desc[:label][:length] = 0
      end
      desc[:type] = type_value
      desc[:count] = @count

      @handle = Native.wgpuDeviceCreateQuerySet(device.handle, desc)
      raise ResourceError, "Failed to create query set" if @handle.null?
    end

    # Destroys the query storage once.
    # @return [void]
    def destroy
      return if @destroyed

      Native.wgpuQuerySetDestroy(@handle)
      @destroyed = true
    end

    # Releases the native query set handle.
    #
    # A query set destroyed through {#destroy} is only marked released because
    # the pinned native implementation cannot safely release it afterward.
    # @return [void]
    def release
      return if @handle.null?

      # Pinned wgpu-native v27 removes a destroyed query set from its storage;
      # calling Release afterward aborts inside Rust instead of being harmless.
      Native.wgpuQuerySetRelease(@handle) unless @destroyed
      @handle = FFI::Pointer::NULL
    end
  end
end
