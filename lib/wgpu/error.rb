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
  class SurfaceAcquisitionError < SurfaceError
    attr_reader :status

    # Creates an acquisition error for a native surface status.
    # @param status [Symbol] native acquisition status
    # @param message [String, nil] optional override message
    def initialize(status, message = nil)
      @status = status
      super(message || "Failed to get current surface texture: #{status}")
    end
  end
  class RenderBundleError < Error; end

  GPUError = Data.define(:type, :message) do
    # Converts a native error-scope result into a typed error.
    # @param error [Hash, nil] native error result
    # @return [GPUError, nil]
    def self.from_hash(error)
      return if error.nil? || error[:type].nil? || error[:type] == :no_error

      new(type: error[:type], message: error[:message].to_s)
    end

    # Returns the Ruby exception class matching this GPU error type.
    # @return [Class<Error>]
    def exception_class
      {
        validation: ValidationError,
        out_of_memory: OutOfMemoryError,
        internal: InternalError,
        device_lost: DeviceLostError
      }.fetch(type, Error)
    end

    # Raises this error as its matching Ruby exception.
    # @return [void]
    # @raise [Error]
    def raise!
      raise exception_class, "GPU error (#{type}): #{message}"
    end

    # Returns a serializable representation of the error.
    # @return [Hash]
    def to_h
      { type:, message: }
    end
  end

  CompilationMessage = Data.define(
    :type,
    :message,
    :line_num,
    :line_pos,
    :offset,
    :length
  ) do
    alias line line_num
    alias column line_pos

    # Formats the diagnostic with source location, severity, and message.
    # @return [String]
    def to_s
      location = line_num&.positive? ? "#{line_num}:#{line_pos}" : "unknown location"
      "#{location}: #{type}: #{message}"
    end
  end
end
