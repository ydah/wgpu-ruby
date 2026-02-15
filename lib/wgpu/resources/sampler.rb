# frozen_string_literal: true

module WGPU
  class Sampler
    attr_reader :handle

    def initialize(device, label: nil, address_mode_u: :clamp_to_edge, address_mode_v: :clamp_to_edge, address_mode_w: :clamp_to_edge, mag_filter: :nearest, min_filter: :nearest, mipmap_filter: :nearest, lod_min_clamp: 0.0, lod_max_clamp: 32.0, compare: nil, max_anisotropy: 1)
      @device = device

      desc = Native::SamplerDescriptor.new
      desc[:next_in_chain] = nil
      if label
        @label_ptr = FFI::MemoryPointer.from_string(label)
        desc[:label][:data] = @label_ptr
        desc[:label][:length] = label.bytesize
      else
        desc[:label][:data] = nil
        desc[:label][:length] = 0
      end
      desc[:address_mode_u] = address_mode_u
      desc[:address_mode_v] = address_mode_v
      desc[:address_mode_w] = address_mode_w
      desc[:mag_filter] = mag_filter
      desc[:min_filter] = min_filter
      desc[:mipmap_filter] = mipmap_filter
      desc[:lod_min_clamp] = lod_min_clamp
      desc[:lod_max_clamp] = lod_max_clamp
      desc[:compare] = compare || :undefined
      desc[:max_anisotropy] = max_anisotropy

      device.push_error_scope(:validation)
      @handle = Native.wgpuDeviceCreateSampler(device.handle, desc)
      error = device.pop_error_scope

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
  end
end
