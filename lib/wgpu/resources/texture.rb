# frozen_string_literal: true

module WGPU
  class Texture
    attr_reader :handle

    def initialize(device, label: nil, size:, format:, usage:, dimension: :d2, mip_level_count: 1, sample_count: 1, view_formats: [])
      @device = device

      desc = Native::TextureDescriptor.new
      desc[:next_in_chain] = nil
      if label
        @label_ptr = FFI::MemoryPointer.from_string(label)
        desc[:label][:data] = @label_ptr
        desc[:label][:length] = label.bytesize
      else
        desc[:label][:data] = nil
        desc[:label][:length] = 0
      end
      desc[:usage] = normalize_usage(usage)
      desc[:dimension] = dimension
      desc[:size][:width] = size[:width] || size[0]
      desc[:size][:height] = size[:height] || size[1] || 1
      desc[:size][:depth_or_array_layers] = size[:depth_or_array_layers] || size[2] || 1
      desc[:format] = format
      desc[:mip_level_count] = mip_level_count
      desc[:sample_count] = sample_count
      desc[:view_format_count] = view_formats.size
      if view_formats.empty?
        @view_formats_ptr = nil
        desc[:view_formats] = nil
      else
        format_values = view_formats.map do |vf|
          vf.is_a?(Integer) ? vf : Native::TextureFormat[vf]
        end
        @view_formats_ptr = FFI::MemoryPointer.new(:uint32, format_values.size)
        @view_formats_ptr.write_array_of_uint32(format_values)
        desc[:view_formats] = @view_formats_ptr
      end

      device.push_error_scope(:validation)
      @handle = Native.wgpuDeviceCreateTexture(device.handle, desc)
      error = device.pop_error_scope

      if @handle.null? || (error[:type] && error[:type] != :no_error)
        msg = error[:message] || "Failed to create texture"
        raise ResourceError, msg
      end
    end

    def self.from_handle(handle)
      texture = allocate
      texture.instance_variable_set(:@handle, handle)
      texture.instance_variable_set(:@device, nil)
      texture
    end

    def create_view(label: nil, format: nil, dimension: nil, base_mip_level: 0, mip_level_count: nil, base_array_layer: 0, array_layer_count: nil, aspect: :all)
      TextureView.new(self,
        label: label,
        format: format,
        dimension: dimension,
        base_mip_level: base_mip_level,
        mip_level_count: mip_level_count,
        base_array_layer: base_array_layer,
        array_layer_count: array_layer_count,
        aspect: aspect
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

    def normalize_usage(usage)
      case usage
      when Integer
        usage
      when Symbol
        Native::TextureUsage[usage]
      when Array
        usage.reduce(0) { |acc, u| acc | Native::TextureUsage[u] }
      else
        raise ArgumentError, "Invalid usage: #{usage}"
      end
    end
  end
end
