# frozen_string_literal: true

module WGPU
  class Texture
    attr_reader :handle, :surface_status

    def initialize(device, label: nil, size:, format:, usage:, dimension: :d2, mip_level_count: 1, sample_count: 1, view_formats: [])
      @device = device

      desc, keepalive = build_descriptor(
        label:,
        size:,
        format:,
        usage:,
        dimension:,
        mip_level_count:,
        sample_count:,
        view_formats:
      )
      @descriptor_keepalive = keepalive

      device.push_error_scope(:validation)
      @handle = Native.wgpuDeviceCreateTexture(device.handle, desc)
      error = device.pop_error_scope
      @descriptor_keepalive = nil

      if @handle.null? || (error[:type] && error[:type] != :no_error)
        msg = error[:message] || "Failed to create texture"
        raise ResourceError, msg
      end
    end

    def self.from_handle(handle, surface_status: nil)
      texture = adopt_native_handle(handle)
      texture.instance_variable_set(:@device, nil)
      texture.instance_variable_set(:@surface_status, surface_status)
      texture
    end

    def create_view(label: nil, format: nil, dimension: nil, base_mip_level: 0, mip_level_count: nil, base_array_layer: 0, array_layer_count: nil, aspect: :all, usage: nil)
      TextureView.new(self,
        label: label,
        format: format,
        dimension: dimension,
        base_mip_level: base_mip_level,
        mip_level_count: mip_level_count,
        base_array_layer: base_array_layer,
        array_layer_count: array_layer_count,
        aspect: aspect,
        usage: usage
      )
    end

    def width
      Native.wgpuTextureGetWidth(@handle)
    end

    def size
      {
        width: width,
        height: height,
        depth_or_array_layers: depth_or_array_layers
      }
    end

    def height
      Native.wgpuTextureGetHeight(@handle)
    end

    def depth_or_array_layers
      Native.wgpuTextureGetDepthOrArrayLayers(@handle)
    end

    def mip_level_count
      Native.wgpuTextureGetMipLevelCount(@handle)
    end

    def sample_count
      Native.wgpuTextureGetSampleCount(@handle)
    end

    def dimension
      Native.wgpuTextureGetDimension(@handle)
    end

    def format
      Native.wgpuTextureGetFormat(@handle)
    end

    def usage
      Native.wgpuTextureGetUsage(@handle)
    end

    def destroy
      Native.wgpuTextureDestroy(@handle)
    end

    def release
      return if @handle.null?
      Native.wgpuTextureRelease(@handle)
      @handle = FFI::Pointer::NULL
    end

    private

    def build_descriptor(label:, size:, format:, usage:, dimension:, mip_level_count:, sample_count:, view_formats:)
      keepalive = []
      DescriptorHelpers.validate_keys!(
        size,
        allowed: [:width, :height, :depth_or_array_layers],
        required: [:width],
        context: "texture size"
      )

      desc = Native::TextureDescriptor.new
      desc[:next_in_chain] = nil
      DescriptorHelpers.set_label(desc, label, keepalive:)
      desc[:usage] = normalize_usage(usage)
      desc[:dimension] = Native::EnumHelper.coerce(Native::TextureDimension, dimension, name: "texture dimension")
      desc[:size][:width] = size[:width] || size[0]
      desc[:size][:height] = size[:height] || size[1] || 1
      desc[:size][:depth_or_array_layers] = size[:depth_or_array_layers] || size[2] || 1
      desc[:format] = Native::EnumHelper.coerce(Native::TextureFormat, format, name: "texture format")
      desc[:mip_level_count] = mip_level_count
      desc[:sample_count] = sample_count
      desc[:view_format_count] = view_formats.size
      format_values = view_formats.map do |view_format|
        Native::EnumHelper.coerce(Native::TextureFormat, view_format, name: "view format")
      end
      desc[:view_formats] = DescriptorHelpers.uint32_array(format_values, keepalive:)
      [desc, keepalive]
    end

    def normalize_usage(usage)
      Native::EnumHelper.coerce_flags(Native::TextureUsage, usage, name: "texture usage")
    end
  end
end
