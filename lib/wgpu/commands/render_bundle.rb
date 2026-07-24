# frozen_string_literal: true

module WGPU
  class RenderBundle
    attr_reader :handle

    # Wraps a reusable native render bundle.
    # @param handle [FFI::Pointer] native render bundle handle
    # @param device [Device, nil] device whose callbacks the render bundle may use
    def initialize(handle, device: nil)
      @handle = handle
      @device = device
    end

    # Releases the native render bundle handle.
    #
    # Calling this method more than once has no effect.
    # @return [void]
    def release
      return if @handle.null?

      Native.wgpuRenderBundleRelease(@handle)
      @handle = FFI::Pointer::NULL
    end
  end
end
