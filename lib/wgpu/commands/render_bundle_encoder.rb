# frozen_string_literal: true

module WGPU
  class RenderBundleEncoder
    attr_reader :handle

    def initialize(device, color_formats:, depth_stencil_format: nil, sample_count: 1,
                   depth_read_only: false, stencil_read_only: false, label: nil)
      @device = device
      @finished = false

      desc = Native::RenderBundleEncoderDescriptor.new
      desc[:next_in_chain] = nil

      if label
        @label_ptr = FFI::MemoryPointer.from_string(label)
        desc[:label][:data] = @label_ptr
        desc[:label][:length] = label.bytesize
      else
        desc[:label][:data] = nil
        desc[:label][:length] = 0
      end

      formats = Array(color_formats).map { |f| Native::TextureFormat[f] }
      @formats_ptr = FFI::MemoryPointer.new(:uint32, formats.size)
      @formats_ptr.write_array_of_uint32(formats)
      desc[:color_format_count] = formats.size
      desc[:color_formats] = @formats_ptr

      desc[:depth_stencil_format] = depth_stencil_format || :undefined
      desc[:sample_count] = sample_count
      desc[:depth_read_only] = depth_read_only ? 1 : 0
      desc[:stencil_read_only] = stencil_read_only ? 1 : 0

      @handle = Native.wgpuDeviceCreateRenderBundleEncoder(device.handle, desc)
      raise RenderBundleError, "Failed to create render bundle encoder" if @handle.null?
    end

    def set_pipeline(pipeline)
      raise RenderBundleError, "Encoder already finished" if @finished

      Native.wgpuRenderBundleEncoderSetPipeline(@handle, pipeline.handle)
    end

    def set_bind_group(index, bind_group, dynamic_offsets: nil)
      raise RenderBundleError, "Encoder already finished" if @finished

      if dynamic_offsets && !dynamic_offsets.empty?
        offsets_ptr = FFI::MemoryPointer.new(:uint32, dynamic_offsets.size)
        offsets_ptr.write_array_of_uint32(dynamic_offsets)
        Native.wgpuRenderBundleEncoderSetBindGroup(@handle, index, bind_group.handle, dynamic_offsets.size, offsets_ptr)
      else
        Native.wgpuRenderBundleEncoderSetBindGroup(@handle, index, bind_group.handle, 0, nil)
      end
    end

    def set_vertex_buffer(slot, buffer, offset: 0, size: nil)
      raise RenderBundleError, "Encoder already finished" if @finished

      size ||= buffer.size - offset
      Native.wgpuRenderBundleEncoderSetVertexBuffer(@handle, slot, buffer.handle, offset, size)
    end

    def set_index_buffer(buffer, format: :uint32, offset: 0, size: nil)
      raise RenderBundleError, "Encoder already finished" if @finished

      size ||= buffer.size - offset
      Native.wgpuRenderBundleEncoderSetIndexBuffer(@handle, buffer.handle, format, offset, size)
    end

    def draw(vertex_count, instance_count: 1, first_vertex: 0, first_instance: 0)
      raise RenderBundleError, "Encoder already finished" if @finished

      Native.wgpuRenderBundleEncoderDraw(@handle, vertex_count, instance_count, first_vertex, first_instance)
    end

    def draw_indexed(index_count, instance_count: 1, first_index: 0, base_vertex: 0, first_instance: 0)
      raise RenderBundleError, "Encoder already finished" if @finished

      Native.wgpuRenderBundleEncoderDrawIndexed(@handle, index_count, instance_count, first_index, base_vertex, first_instance)
    end

    def draw_indirect(buffer, offset: 0)
      raise RenderBundleError, "Encoder already finished" if @finished

      Native.wgpuRenderBundleEncoderDrawIndirect(@handle, buffer.handle, offset)
    end

    def draw_indexed_indirect(buffer, offset: 0)
      raise RenderBundleError, "Encoder already finished" if @finished

      Native.wgpuRenderBundleEncoderDrawIndexedIndirect(@handle, buffer.handle, offset)
    end

    def push_debug_group(label)
      raise RenderBundleError, "Encoder already finished" if @finished

      label_view = Native::StringView.new
      label_ptr = FFI::MemoryPointer.from_string(label)
      label_view[:data] = label_ptr
      label_view[:length] = label.bytesize
      Native.wgpuRenderBundleEncoderPushDebugGroup(@handle, label_view)
    end

    def pop_debug_group
      raise RenderBundleError, "Encoder already finished" if @finished

      Native.wgpuRenderBundleEncoderPopDebugGroup(@handle)
    end

    def insert_debug_marker(label)
      raise RenderBundleError, "Encoder already finished" if @finished

      label_view = Native::StringView.new
      label_ptr = FFI::MemoryPointer.from_string(label)
      label_view[:data] = label_ptr
      label_view[:length] = label.bytesize
      Native.wgpuRenderBundleEncoderInsertDebugMarker(@handle, label_view)
    end

    def finish(label: nil)
      raise RenderBundleError, "Encoder already finished" if @finished

      @finished = true

      desc = nil
      if label
        desc = Native::RenderBundleDescriptor.new
        desc[:next_in_chain] = nil
        label_ptr = FFI::MemoryPointer.from_string(label)
        desc[:label][:data] = label_ptr
        desc[:label][:length] = label.bytesize
      end

      bundle_handle = Native.wgpuRenderBundleEncoderFinish(@handle, desc)
      raise RenderBundleError, "Failed to finish render bundle encoder" if bundle_handle.null?

      RenderBundle.new(bundle_handle)
    end

    def release
      return if @handle.null?

      Native.wgpuRenderBundleEncoderRelease(@handle)
      @handle = FFI::Pointer::NULL
    end
  end
end
