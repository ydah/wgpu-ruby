# frozen_string_literal: true

module WGPU
  class BindGroup
    attr_reader :handle

    # Creates bindings between shader slots and GPU resources.
    # @param device [Device] owning device
    # @param layout [BindGroupLayout] layout the entries must match
    # @param entries [Array<Hash>] resource binding descriptors
    # @raise [PipelineError] if native validation or creation fails
    def initialize(device, label: nil, layout:, entries:)
      @device = device

      entries_array = entries.map { |e| create_entry(e) }
      entries_ptr = FFI::MemoryPointer.new(Native::BindGroupEntry, entries_array.size)
      entries_array.each_with_index do |entry, i|
        offset = i * Native::BindGroupEntry.size
        (entries_ptr + offset).put_bytes(0, entry.pointer.read_bytes(Native::BindGroupEntry.size))
      end

      desc = Native::BindGroupDescriptor.new
      desc[:next_in_chain] = nil
      if label
        label_ptr = FFI::MemoryPointer.from_string(label)
        desc[:label][:data] = label_ptr
        desc[:label][:length] = label.bytesize
      else
        desc[:label][:data] = nil
        desc[:label][:length] = 0
      end
      desc[:layout] = layout.handle
      desc[:entry_count] = entries_array.size
      desc[:entries] = entries_ptr

      device.push_error_scope(:validation)
      @handle = Native.wgpuDeviceCreateBindGroup(device.handle, desc)
      error = device.pop_error_scope

      if @handle.null? || (error[:type] && error[:type] != :no_error)
        msg = error[:message] || "Failed to create bind group"
        raise PipelineError, msg
      end
    end

    # Releases the native bind group handle.
    #
    # Calling this method more than once has no effect.
    # @return [void]
    def release
      return if @handle.null?
      Native.wgpuBindGroupRelease(@handle)
      @handle = FFI::Pointer::NULL
    end

    private

    def create_entry(entry_hash)
      DescriptorHelpers.validate_keys!(
        entry_hash,
        allowed: %i[binding buffer offset size sampler texture_view],
        required: [:binding],
        context: "bind group entry"
      )
      resources = %i[buffer sampler texture_view].select { |key| entry_hash[key] }
      unless resources.one?
        raise ArgumentError,
          "bind group entry must define exactly one resource (:buffer, :sampler, or :texture_view)"
      end

      entry = Native::BindGroupEntry.new
      entry[:next_in_chain] = nil
      entry[:binding] = entry_hash[:binding]

      if entry_hash[:buffer]
        buffer = entry_hash[:buffer]
        entry[:buffer] = buffer.handle
        entry[:offset] = entry_hash[:offset] || 0
        entry[:size] = entry_hash[:size] || buffer.size
      else
        entry[:buffer] = nil
        entry[:offset] = 0
        entry[:size] = 0
      end

      if entry_hash[:sampler]
        entry[:sampler] = entry_hash[:sampler].handle
      else
        entry[:sampler] = nil
      end

      if entry_hash[:texture_view]
        entry[:texture_view] = entry_hash[:texture_view].handle
      else
        entry[:texture_view] = nil
      end

      entry
    end
  end
end
