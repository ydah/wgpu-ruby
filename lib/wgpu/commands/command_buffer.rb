# frozen_string_literal: true

module WGPU
  class CommandBuffer
    attr_reader :handle

    # Wraps an encoded native command buffer.
    # @param handle [FFI::Pointer] native command buffer handle
    # @param device [Device, nil] device whose callbacks the command buffer may use
    def initialize(handle, device: nil)
      @handle = handle
      @device = device
      @submitted = false
    end

    # Reports whether this command buffer has been submitted.
    # @return [Boolean]
    def submitted?
      @submitted
    end

    # Marks this command buffer as submitted.
    # @raise [CommandError] if it was already submitted
    # @return [void]
    def mark_submitted!
      raise CommandError, "Command buffer has already been submitted" if @submitted

      @submitted = true
    end

    # Releases the native command buffer handle.
    #
    # Calling this method more than once has no effect.
    # @return [void]
    def release
      return if @handle.null?
      Native.wgpuCommandBufferRelease(@handle)
      @handle = FFI::Pointer::NULL
    end
  end
end
