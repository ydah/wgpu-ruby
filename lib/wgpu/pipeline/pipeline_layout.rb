# frozen_string_literal: true

module WGPU
  class PipelineLayout
    attr_reader :handle

    def initialize(device, label: nil, bind_group_layouts:)
      @device = device

      layouts = Array(bind_group_layouts)
      layouts_ptr = FFI::MemoryPointer.new(:pointer, layouts.size)
      layouts_ptr.write_array_of_pointer(layouts.map(&:handle))

      desc = Native::PipelineLayoutDescriptor.new
      desc[:next_in_chain] = nil
      if label
        label_ptr = FFI::MemoryPointer.from_string(label)
        desc[:label][:data] = label_ptr
        desc[:label][:length] = label.bytesize
      else
        desc[:label][:data] = nil
        desc[:label][:length] = 0
      end
      desc[:bind_group_layout_count] = layouts.size
      desc[:bind_group_layouts] = layouts_ptr

      device.push_error_scope(:validation)
      @handle = Native.wgpuDeviceCreatePipelineLayout(device.handle, desc)
      error = device.pop_error_scope

      if @handle.null? || (error[:type] && error[:type] != :no_error)
        msg = error[:message] || "Failed to create pipeline layout"
        raise PipelineError, msg
      end
    end

    def release
      return if @handle.null?
      Native.wgpuPipelineLayoutRelease(@handle)
      @handle = FFI::Pointer::NULL
    end
  end
end
