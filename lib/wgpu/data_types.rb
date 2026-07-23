# frozen_string_literal: true

module WGPU
  module DataTypes
    FORMATS = {
      f32: ["e*", 4],
      f64: ["E*", 8],
      u32: ["L<*", 4],
      i32: ["l<*", 4],
      u16: ["S<*", 2],
      u8: ["C*", 1]
    }.freeze

    module_function

    # Encodes Ruby values in little-endian native transfer format.
    # @param values [Array] values to encode
    # @param type [Symbol] element type
    # @return [String] encoded bytes
    def pack(values, type: :f32)
      format, = format_for(type)
      Array(values).pack(format)
    rescue RangeError => e
      raise ArgumentError, "value is out of range for #{type}: #{e.message}"
    end

    # Decodes little-endian transfer bytes into Ruby values.
    # @param bytes [String] encoded bytes
    # @param type [Symbol] element type
    # @return [Array]
    def unpack(bytes, type: :f32)
      format, byte_size = format_for(type)
      unless (bytes.bytesize % byte_size).zero?
        raise ArgumentError, "#{type} data size must be a multiple of #{byte_size} bytes"
      end

      bytes.unpack(format)
    end

    # Returns the byte width of one typed value.
    # @param type [Symbol] element type
    # @return [Integer]
    def byte_size(type)
      format_for(type).last
    end

    # Converts data to an FFI pointer and reports its byte length.
    # @return [Array(FFI::Pointer, Integer)] pointer and byte length
    def to_pointer(data, type: :f32)
      return [data, pointer_size(data)] if data.is_a?(FFI::Pointer)

      bytes = data.is_a?(String) ? data : pack(data, type:)
      pointer = FFI::MemoryPointer.new(:char, bytes.bytesize)
      pointer.put_bytes(0, bytes)
      [pointer, bytes.bytesize]
    end

    # Validates a non-negative aligned byte value.
    # @return [Integer] normalized value
    # @raise [ArgumentError] if negative or misaligned
    def validate_alignment!(value, alignment, name:)
      integer = Integer(value)
      raise ArgumentError, "#{name} must be non-negative" if integer.negative?
      return integer if (integer % alignment).zero?

      raise ArgumentError, "#{name} must be aligned to #{alignment} bytes (got #{integer})"
    end

    def format_for(type)
      FORMATS.fetch(type.to_sym)
    rescue NoMethodError, KeyError
      raise ArgumentError, "Unknown data type #{type.inspect}. Valid values: #{FORMATS.keys.map(&:inspect).join(", ")}"
    end
    private_class_method :format_for

    def pointer_size(pointer)
      pointer.size
    rescue NoMethodError
      raise ArgumentError, "FFI pointer must have a known size; pass size explicitly"
    end
    private_class_method :pointer_size
  end
end
