# frozen_string_literal: true

module WGPU
  class Error < StandardError; end
  class InitializationError < Error; end
  class AdapterError < Error; end
  class DeviceError < Error; end
  class BufferError < Error; end
  class TextureError < Error; end
  class ResourceError < Error; end
  class ShaderError < Error; end
  class PipelineError < Error; end
  class CommandError < Error; end
  class SurfaceError < Error; end
  class RenderBundleError < Error; end
end
