# frozen_string_literal: true

module WGPU
  class QuerySet
    attr_reader :handle

    def initialize(device, label: nil, type:, count:)
      @device = device

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
      desc[:type] = type
      desc[:count] = count

      @handle = Native.wgpuDeviceCreateQuerySet(device.handle, desc)
      raise ResourceError, "Failed to create query set" if @handle.null?
    end

    def count
      Native.wgpuQuerySetGetCount(@handle)
    end

    def type
      Native.wgpuQuerySetGetType(@handle)
    end

    def destroy
      Native.wgpuQuerySetDestroy(@handle)
    end

    def release
      return if @handle.null?
      Native.wgpuQuerySetRelease(@handle)
      @handle = FFI::Pointer::NULL
    end
  end
end
