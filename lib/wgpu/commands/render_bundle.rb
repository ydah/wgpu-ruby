# frozen_string_literal: true

module WGPU
  class RenderBundle
    attr_reader :handle

    def initialize(handle)
      @handle = handle
    end

    def release
      return if @handle.null?

      Native.wgpuRenderBundleRelease(@handle)
      @handle = FFI::Pointer::NULL
    end
  end
end
