# frozen_string_literal: true

module WGPU
  class Sampler
    attr_reader :handle

    def initialize(device, label: nil, address_mode_u: :clamp_to_edge, address_mode_v: :clamp_to_edge, address_mode_w: :clamp_to_edge, mag_filter: :nearest, min_filter: :nearest, mipmap_filter: :nearest, lod_min_clamp: 0.0, lod_max_clamp: 32.0, compare: nil, max_anisotropy: 1)
      @device = device

      desc, keepalive = build_descriptor(
        label:,
        address_mode_u:,
        address_mode_v:,
        address_mode_w:,
        mag_filter:,
        min_filter:,
        mipmap_filter:,
        lod_min_clamp:,
        lod_max_clamp:,
        compare:,
        max_anisotropy:
      )
      @descriptor_keepalive = keepalive

      device.push_error_scope(:validation)
      @handle = Native.wgpuDeviceCreateSampler(device.handle, desc)
      error = device.pop_error_scope
      @descriptor_keepalive = nil

      if @handle.null? || (error[:type] && error[:type] != :no_error)
        msg = error[:message] || "Failed to create sampler"
        raise ResourceError, msg
      end
    end

    def release
      return if @handle.null?
      Native.wgpuSamplerRelease(@handle)
      @handle = FFI::Pointer::NULL
    end

    private

    def build_descriptor(label:, address_mode_u:, address_mode_v:, address_mode_w:, mag_filter:, min_filter:,
                         mipmap_filter:, lod_min_clamp:, lod_max_clamp:, compare:, max_anisotropy:)
      keepalive = []
      desc = Native::SamplerDescriptor.new
      desc[:next_in_chain] = nil
      DescriptorHelpers.set_label(desc, label, keepalive:)
      desc[:address_mode_u] = Native::EnumHelper.coerce(Native::AddressMode, address_mode_u, name: "address mode")
      desc[:address_mode_v] = Native::EnumHelper.coerce(Native::AddressMode, address_mode_v, name: "address mode")
      desc[:address_mode_w] = Native::EnumHelper.coerce(Native::AddressMode, address_mode_w, name: "address mode")
      desc[:mag_filter] = Native::EnumHelper.coerce(Native::FilterMode, mag_filter, name: "mag filter")
      desc[:min_filter] = Native::EnumHelper.coerce(Native::FilterMode, min_filter, name: "min filter")
      desc[:mipmap_filter] = Native::EnumHelper.coerce(Native::MipmapFilterMode, mipmap_filter, name: "mipmap filter")
      desc[:lod_min_clamp] = lod_min_clamp
      desc[:lod_max_clamp] = lod_max_clamp
      desc[:compare] = Native::EnumHelper.coerce(Native::CompareFunction, compare || :undefined, name: "compare function")
      desc[:max_anisotropy] = max_anisotropy
      [desc, keepalive]
    end
  end
end
