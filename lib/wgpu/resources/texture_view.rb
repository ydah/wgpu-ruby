# frozen_string_literal: true

module WGPU
  class TextureView
    attr_reader :handle, :texture

    def initialize(texture, label: nil, format: nil, dimension: nil, base_mip_level: 0, mip_level_count: nil, base_array_layer: 0, array_layer_count: nil, aspect: :all, usage: nil)
      @texture = texture

      desc = Native::TextureViewDescriptor.new
      desc[:next_in_chain] = nil
      if label
        @label_ptr = FFI::MemoryPointer.from_string(label)
        desc[:label][:data] = @label_ptr
        desc[:label][:length] = label.bytesize
      else
        desc[:label][:data] = nil
        desc[:label][:length] = 0
      end
      desc[:format] = Native::EnumHelper.coerce(
        Native::TextureFormat,
        format || :undefined,
        name: "texture view format"
      )
      desc[:dimension] = Native::EnumHelper.coerce(
        Native::TextureViewDimension,
        dimension || :undefined,
        name: "texture view dimension"
      )
      desc[:base_mip_level] = base_mip_level
      desc[:mip_level_count] = mip_level_count || 0xFFFFFFFF
      desc[:base_array_layer] = base_array_layer
      desc[:array_layer_count] = array_layer_count || 0xFFFFFFFF
      desc[:aspect] = Native::EnumHelper.coerce(Native::TextureAspect, aspect, name: "texture aspect")
      desc[:usage] = Native::EnumHelper.coerce_flags(
        Native::TextureUsage,
        usage || :none,
        name: "texture view usage"
      )

      @handle = Native.wgpuTextureCreateView(texture.handle, desc)
      raise ResourceError, "Failed to create texture view" if @handle.null?
    end

    def self.from_handle(handle)
      view = allocate
      view.instance_variable_set(:@handle, handle)
      view.instance_variable_set(:@texture, nil)
      view
    end

    def size
      @texture&.size
    end

    def release
      return if @handle.null?
      Native.wgpuTextureViewRelease(@handle)
      @handle = FFI::Pointer::NULL
    end
  end
end
