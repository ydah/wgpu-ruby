# frozen_string_literal: true

module WGPU
  class Error < StandardError; end
  class ValidationError < Error; end
  class OutOfMemoryError < Error; end
  class InternalError < Error; end
  class DeviceLostError < Error; end
  class TimeoutError < Error; end
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

  GPUError = Data.define(:type, :message) do
    def self.from_hash(error)
      return if error.nil? || error[:type].nil? || error[:type] == :no_error

      new(type: error[:type], message: error[:message].to_s)
    end

    def exception_class
      {
        validation: ValidationError,
        out_of_memory: OutOfMemoryError,
        internal: InternalError,
        device_lost: DeviceLostError
      }.fetch(type, Error)
    end

    def raise!
      raise exception_class, "GPU error (#{type}): #{message}"
    end

    def to_h
      { type:, message: }
    end
  end
end
