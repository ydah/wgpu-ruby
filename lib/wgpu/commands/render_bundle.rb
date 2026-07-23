# frozen_string_literal: true

module WGPU
  class RenderBundle
    attr_reader :handle

    # Wraps a reusable native render bundle.
    # @param handle [FFI::Pointer] native render bundle handle
    def initialize(handle)
      @handle = handle
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
