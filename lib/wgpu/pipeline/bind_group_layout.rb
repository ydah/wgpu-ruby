# frozen_string_literal: true

module WGPU
  class BindGroupLayout
    attr_reader :handle

    # Wraps a native bind group layout handle owned by the caller.
    #
    # @param handle [FFI::Pointer] native bind group layout handle
    # @param device [Device, nil] device whose callbacks the layout may use
    # @return [BindGroupLayout] adopted wrapper
    def self.from_handle(handle, device: nil)
      layout = adopt_native_handle(handle)
      layout.instance_variable_set(:@device, device)
      layout.send(:attach_device_callback_lifetime, device)
      layout
    end

    # Creates a layout describing shader-visible resource bindings.
    # @param device [Device] owning device
    # @param entries [Array<Hash>] binding layout descriptors
    # @raise [PipelineError] if native validation or creation fails
    def initialize(device, label: nil, entries:)
      @device = device
      desc, @descriptor_keepalive = build_descriptor(label:, entries:)

      device.push_error_scope(:validation)
      @handle = Native.wgpuDeviceCreateBindGroupLayout(device.handle, desc)
      error = device.pop_error_scope
      @descriptor_keepalive = nil

      if @handle.null? || (error[:type] && error[:type] != :no_error)
        msg = error[:message] || "Failed to create bind group layout"
        raise PipelineError, msg
      end
    end

    # Releases the native bind group layout handle.
    #
    # Calling this method more than once has no effect.
    # @return [void]
    def release
      return if @handle.null?
      Native.wgpuBindGroupLayoutRelease(@handle)
      @handle = FFI::Pointer::NULL
    end

    private

    def build_descriptor(label:, entries:)
      keepalive = []
      entries_array = entries.map { |entry| create_entry(entry) }
      entries_ptr = FFI::MemoryPointer.new(Native::BindGroupLayoutEntry, entries_array.size)
      entries_array.each_with_index do |entry, index|
        offset = index * Native::BindGroupLayoutEntry.size
        (entries_ptr + offset).put_bytes(0, entry.pointer.read_bytes(Native::BindGroupLayoutEntry.size))
      end
      keepalive.concat(entries_array)
      keepalive << entries_ptr

      desc = Native::BindGroupLayoutDescriptor.new
      desc[:next_in_chain] = nil
      DescriptorHelpers.set_label(desc, label, keepalive:)
      desc[:entry_count] = entries_array.size
      desc[:entries] = entries_ptr
      [desc, keepalive]
    end

    def create_entry(entry_hash)
      DescriptorHelpers.validate_keys!(
        entry_hash,
        allowed: %i[binding visibility buffer sampler texture storage_texture],
        required: %i[binding visibility],
        context: "bind group layout entry"
      )
      variants = %i[buffer sampler texture storage_texture].select { |key| entry_hash[key] }
      unless variants.one?
        raise ArgumentError,
          "bind group layout entry must define exactly one resource variant " \
          "(:buffer, :sampler, :texture, or :storage_texture)"
      end

      entry = Native::BindGroupLayoutEntry.new
      entry[:next_in_chain] = nil
      entry[:binding] = entry_hash[:binding]
      entry[:visibility] = normalize_visibility(entry_hash[:visibility])

      entry[:buffer][:next_in_chain] = nil
      entry[:buffer][:type] = :binding_not_used
      entry[:buffer][:has_dynamic_offset] = 0
      entry[:buffer][:min_binding_size] = 0

      entry[:sampler][:next_in_chain] = nil
      entry[:sampler][:type] = :binding_not_used

      entry[:texture][:next_in_chain] = nil
      entry[:texture][:sample_type] = :binding_not_used
      entry[:texture][:view_dimension] = :undefined
      entry[:texture][:multisampled] = 0

      entry[:storage_texture][:next_in_chain] = nil
      entry[:storage_texture][:access] = :binding_not_used
      entry[:storage_texture][:format] = :undefined
      entry[:storage_texture][:view_dimension] = :undefined

      if entry_hash[:buffer]
        buffer_info = entry_hash[:buffer]
        DescriptorHelpers.validate_keys!(
          buffer_info,
          allowed: %i[type has_dynamic_offset min_binding_size],
          context: "buffer binding layout"
        )
        entry[:buffer][:type] = Native::EnumHelper.coerce(
          Native::BufferBindingType,
          buffer_info[:type] || :storage,
          name: "buffer binding type"
        )
        entry[:buffer][:has_dynamic_offset] = buffer_info[:has_dynamic_offset] ? 1 : 0
        entry[:buffer][:min_binding_size] = buffer_info[:min_binding_size] || 0
      end

      if entry_hash[:sampler]
        sampler_info = entry_hash[:sampler]
        DescriptorHelpers.validate_keys!(
          sampler_info,
          allowed: [:type],
          context: "sampler binding layout"
        )
        entry[:sampler][:type] = Native::EnumHelper.coerce(
          Native::SamplerBindingType,
          sampler_info[:type] || :filtering,
          name: "sampler binding type"
        )
      end

      if entry_hash[:texture]
        texture_info = entry_hash[:texture]
        DescriptorHelpers.validate_keys!(
          texture_info,
          allowed: %i[sample_type view_dimension multisampled],
          context: "texture binding layout"
        )
        entry[:texture][:sample_type] = Native::EnumHelper.coerce(
          Native::TextureSampleType,
          texture_info[:sample_type] || :float,
          name: "texture sample type"
        )
        entry[:texture][:view_dimension] = Native::EnumHelper.coerce(
          Native::TextureViewDimension,
          texture_info[:view_dimension] || :d2,
          name: "texture view dimension"
        )
        entry[:texture][:multisampled] = texture_info[:multisampled] ? 1 : 0
      end

      if entry_hash[:storage_texture]
        st_info = entry_hash[:storage_texture]
        DescriptorHelpers.validate_keys!(
          st_info,
          allowed: %i[access format view_dimension],
          required: [:format],
          context: "storage texture binding layout"
        )
        entry[:storage_texture][:access] = Native::EnumHelper.coerce(
          Native::StorageTextureAccess,
          st_info[:access] || :write_only,
          name: "storage texture access"
        )
        entry[:storage_texture][:format] = Native::EnumHelper.coerce(
          Native::TextureFormat,
          st_info.fetch(:format),
          name: "storage texture format"
        )
        entry[:storage_texture][:view_dimension] = Native::EnumHelper.coerce(
          Native::TextureViewDimension,
          st_info[:view_dimension] || :d2,
          name: "texture view dimension"
        )
      end

      entry
    end

    def normalize_visibility(visibility)
      Native::EnumHelper.coerce_flags(Native::ShaderStage, visibility, name: "shader visibility")
    end
  end
end
