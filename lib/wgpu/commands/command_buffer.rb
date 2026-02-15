# frozen_string_literal: true

module WGPU
  class CommandBuffer
    attr_reader :handle

    def initialize(handle)
      @handle = handle
    end

    def release
      return if @handle.null?
      Native.wgpuCommandBufferRelease(@handle)
      @handle = FFI::Pointer::NULL
    end
  end
end
