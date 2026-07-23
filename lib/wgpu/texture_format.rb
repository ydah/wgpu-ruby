# frozen_string_literal: true

module WGPU
  module TextureFormat
    COPY_ALIGNMENT = 256

    module_function

    def block_size(format, aspect: :all)
      block_info(format, aspect:).last
    end

    def block_dimensions(format)
      block_info(format).first(2)
    end

    def bytes_per_row(width, format, aspect: :all)
      block_width, _, bytes = block_info(format, aspect:)
      ((Integer(width) + block_width - 1) / block_width) * bytes
    end

    def aligned_bytes_per_row(width, format, aspect: :all, alignment: COPY_ALIGNMENT)
      row_bytes = bytes_per_row(width, format, aspect:)
      ((row_bytes + alignment - 1) / alignment) * alignment
    end

    def block_info(format, aspect: :all)
      name = normalize_format(format)
      special = depth_stencil_block_info(name, aspect)
      return special if special

      case name.to_s
      when /\Ar8_/
        [1, 1, 1]
      when /\A(?:r16_|rg8_)/
        [1, 1, 2]
      when /\A(?:r32_|rg16_|rgba8_|bgra8_|rgb10a2_|rg11b10_|rgb9e5_)/
        [1, 1, 4]
      when /\A(?:rg32_|rgba16_)/
        [1, 1, 8]
      when /\Argba32_/
        [1, 1, 16]
      when /\A(?:bc(?:1|4)|etc2_rgb8|etc2_rgb8a1|eac_r11)_/
        [4, 4, 8]
      when /\A(?:bc(?:2|3|5|6h|7)|etc2_rgba8|eac_rg11)_/
        [4, 4, 16]
      when /\Aastc_(\d+)x(\d+)_/
        [Regexp.last_match(1).to_i, Regexp.last_match(2).to_i, 16]
      else
        raise ArgumentError, "No texel block copy footprint for #{name.inspect}"
      end
    end

    def normalize_format(format)
      return format if format.is_a?(Symbol) &&
        Native::TextureFormat.to_h.key?(format)

      value = Native::EnumHelper.coerce(Native::TextureFormat, format, name: "texture format")
      Native::TextureFormat[value] || format
    end
    private_class_method :normalize_format

    def depth_stencil_block_info(format, aspect)
      case format
      when :stencil8
        [1, 1, 1]
      when :depth16_unorm
        [1, 1, 2]
      when :depth32_float
        [1, 1, 4]
      when :depth32_float_stencil8
        return [1, 1, 4] if aspect == :depth_only
        return [1, 1, 1] if aspect == :stencil_only

        raise ArgumentError, "depth32_float_stencil8 copies require :depth_only or :stencil_only aspect"
      when :depth24_plus, :depth24_plus_stencil8
        raise ArgumentError, "#{format} has no portable texel block copy footprint"
      end
    end
    private_class_method :depth_stencil_block_info
  end
end
