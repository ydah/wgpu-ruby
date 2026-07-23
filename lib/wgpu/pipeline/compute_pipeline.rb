# frozen_string_literal: true

module WGPU
  class ComputePipeline
    attr_reader :handle

    def initialize(device, label: nil, layout:, compute:)
      @device = device
      desc, @pointers = build_descriptor(label:, layout:, compute:)

      device.push_error_scope(:validation)
      @handle = Native.wgpuDeviceCreateComputePipeline(device.handle, desc)
      error = device.pop_error_scope

      if @handle.null? || (error[:type] && error[:type] != :no_error)
        msg = error[:message] || "Failed to create compute pipeline"
        raise PipelineError, msg
      end
    end

    def get_bind_group_layout(index)
      handle = Native.wgpuComputePipelineGetBindGroupLayout(@handle, index)
      raise PipelineError, "Failed to get bind group layout at index #{index}" if handle.null?
      BindGroupLayout.from_handle(handle)
    end

    def release
      return if @handle.null?
      Native.wgpuComputePipelineRelease(@handle)
      @handle = FFI::Pointer::NULL
    end

    private

    def build_descriptor(label:, layout:, compute:)
      DescriptorHelpers.validate_keys!(
        compute,
        allowed: %i[module entry_point constants],
        required: [:module],
        context: "compute pipeline stage"
      )
      @pointers = []
      entry_point = compute[:entry_point] || "main"
      entry_point_ptr = FFI::MemoryPointer.from_string(entry_point)
      @pointers << entry_point_ptr

      desc = Native::ComputePipelineDescriptor.new
      desc[:next_in_chain] = nil
      DescriptorHelpers.set_label(desc, label, keepalive: @pointers)
      desc[:layout] = normalize_layout(layout)
      desc[:compute][:next_in_chain] = nil
      desc[:compute][:module] = compute.fetch(:module).handle
      desc[:compute][:entry_point][:data] = entry_point_ptr
      desc[:compute][:entry_point][:length] = entry_point.bytesize
      desc[:compute][:constant_count] = 0
      desc[:compute][:constants] = nil
      setup_constants(desc[:compute], compute[:constants])

      [desc, @pointers]
    end

    def normalize_layout(layout)
      return nil if layout.nil? || layout == :auto || layout == "auto"
      layout.handle
    end

    def setup_constants(stage_desc, constants)
      return if constants.nil? || constants.empty?

      constants_ptr = FFI::MemoryPointer.new(Native::ConstantEntry, constants.size)
      @pointers << constants_ptr

      constants.each_with_index do |(key, value), i|
        entry_ptr = constants_ptr + (i * Native::ConstantEntry.size)
        entry = Native::ConstantEntry.new(entry_ptr)
        entry[:next_in_chain] = nil

        key_str = key.to_s
        key_ptr = FFI::MemoryPointer.from_string(key_str)
        @pointers << key_ptr
        entry[:key][:data] = key_ptr
        entry[:key][:length] = key_str.bytesize
        entry[:value] = value.to_f
      end

      stage_desc[:constant_count] = constants.size
      stage_desc[:constants] = constants_ptr
    end
  end
end
