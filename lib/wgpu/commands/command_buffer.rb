# frozen_string_literal: true

module WGPU
  class CommandBuffer
    attr_reader :handle

    def initialize(handle)
      @handle = handle
      @submitted = false
    end

    def submitted?
      @submitted
    end

    def mark_submitted!
      raise CommandError, "Command buffer has already been submitted" if @submitted

      @submitted = true
    end

    def release
      return if @handle.null?
      Native.wgpuCommandBufferRelease(@handle)
      @handle = FFI::Pointer::NULL
    end
  end
end
