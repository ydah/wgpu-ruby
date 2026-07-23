# frozen_string_literal: true

module WGPU
  class BindGroupLayout
    attr_reader :handle

    def self.from_handle(handle)
      layout = allocate
      layout.instance_variable_set(:@handle, handle)
      layout.instance_variable_set(:@device, nil)
      layout
    end

    def initialize(device, label: nil, entries:)
      @device = device

      entries_array = entries.map { |e| create_entry(e) }
      entries_ptr = FFI::MemoryPointer.new(Native::BindGroupLayoutEntry, entries_array.size)
      entries_array.each_with_index do |entry, i|
        offset = i * Native::BindGroupLayoutEntry.size
        (entries_ptr + offset).put_bytes(0, entry.pointer.read_bytes(Native::BindGroupLayoutEntry.size))
      end

      desc = Native::BindGroupLayoutDescriptor.new
      desc[:next_in_chain] = nil
      if label
        label_ptr = FFI::MemoryPointer.from_string(label)
        desc[:label][:data] = label_ptr
        desc[:label][:length] = label.bytesize
      else
        desc[:label][:data] = nil
        desc[:label][:length] = 0
      end
      desc[:entry_count] = entries_array.size
      desc[:entries] = entries_ptr

      device.push_error_scope(:validation)
      @handle = Native.wgpuDeviceCreateBindGroupLayout(device.handle, desc)
      error = device.pop_error_scope

      if @handle.null? || (error[:type] && error[:type] != :no_error)
        msg = error[:message] || "Failed to create bind group layout"
        raise PipelineError, msg
      end
    end

    def release
      return if @handle.null?
      Native.wgpuBindGroupLayoutRelease(@handle)
      @handle = FFI::Pointer::NULL
    end

    private

    def create_entry(entry_hash)
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
        entry[:sampler][:type] = Native::EnumHelper.coerce(
          Native::SamplerBindingType,
          sampler_info[:type] || :filtering,
          name: "sampler binding type"
        )
      end

      if entry_hash[:texture]
        texture_info = entry_hash[:texture]
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
