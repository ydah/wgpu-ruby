# frozen_string_literal: true

module WGPU
  class ComputePipeline
    attr_reader :handle

    # Creates a compute pipeline.
    # @param device [Device] owning device
    # @param layout [PipelineLayout, :auto, nil] pipeline layout
    # @param compute [Hash] programmable compute stage descriptor
    # @raise [PipelineError] if native validation or creation fails
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

    # Returns the bind group layout inferred or assigned at an index.
    # @param index [Integer] bind group index
    # @return [BindGroupLayout]
    # @raise [PipelineError] if no native layout is returned
    def get_bind_group_layout(index)
      handle = Native.wgpuComputePipelineGetBindGroupLayout(@handle, index)
      raise PipelineError, "Failed to get bind group layout at index #{index}" if handle.null?
      BindGroupLayout.from_handle(handle, device: @device)
    end

    # Releases the native compute pipeline handle.
    #
    # Calling this method more than once has no effect.
    # @return [void]
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

      desc = Native::ComputePipelineDescriptor.new
      desc[:next_in_chain] = nil
      DescriptorHelpers.set_label(desc, label, keepalive: @pointers)
      desc[:layout] = normalize_layout(layout)
      desc[:compute][:next_in_chain] = nil
      desc[:compute][:module] = compute.fetch(:module).handle
      DescriptorHelpers.set_nullable_string_view(
        desc[:compute][:entry_point],
        compute[:entry_point],
        keepalive: @pointers
      )
      DescriptorHelpers.set_constants(desc[:compute], compute[:constants], keepalive: @pointers)

      [desc, @pointers]
    end

    def normalize_layout(layout)
      return nil if layout.nil? || layout == :auto || layout == "auto"
      layout.handle
    end
  end
end
