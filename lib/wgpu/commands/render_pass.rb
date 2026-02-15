# frozen_string_literal: true

module WGPU
  class RenderPass
    attr_reader :handle

    def initialize(encoder, label: nil, color_attachments:, depth_stencil_attachment: nil, occlusion_query_set: nil, timestamp_writes: nil, max_draw_count: nil)
      @encoder = encoder
      @pointers = []
      @max_draw_count = max_draw_count

      desc = Native::RenderPassDescriptor.new
      desc[:next_in_chain] = nil
      setup_label(desc, label)

      color_attachments_ptr = setup_color_attachments(color_attachments)
      desc[:color_attachment_count] = color_attachments.size
      desc[:color_attachments] = color_attachments_ptr

      if depth_stencil_attachment
        ds_ptr = setup_depth_stencil_attachment(depth_stencil_attachment)
        desc[:depth_stencil_attachment] = ds_ptr
      else
        desc[:depth_stencil_attachment] = nil
      end

      desc[:occlusion_query_set] = occlusion_query_set&.handle
      if timestamp_writes
        ts = Native::RenderPassTimestampWrites.new
        ts[:query_set] = timestamp_writes.fetch(:query_set).handle
        ts[:beginning_of_pass_write_index] = timestamp_writes[:beginning_of_pass_write_index] || 0xFFFFFFFF
        ts[:end_of_pass_write_index] = timestamp_writes[:end_of_pass_write_index] || 0xFFFFFFFF
        @pointers << ts
        desc[:timestamp_writes] = ts.to_ptr
      else
        desc[:timestamp_writes] = nil
      end

      @handle = Native.wgpuCommandEncoderBeginRenderPass(encoder.handle, desc)
      raise CommandError, "Failed to begin render pass" if @handle.null?
    end

    def set_pipeline(pipeline)
      Native.wgpuRenderPassEncoderSetPipeline(@handle, pipeline.handle)
    end

    def set_bind_group(index, bind_group, dynamic_offsets: [])
      if dynamic_offsets.empty?
        Native.wgpuRenderPassEncoderSetBindGroup(@handle, index, bind_group.handle, 0, nil)
      else
        offsets_ptr = FFI::MemoryPointer.new(:uint32, dynamic_offsets.size)
        offsets_ptr.write_array_of_uint32(dynamic_offsets)
        Native.wgpuRenderPassEncoderSetBindGroup(@handle, index, bind_group.handle, dynamic_offsets.size, offsets_ptr)
      end
    end

    def set_vertex_buffer(slot, buffer, offset: 0, size: nil)
      size ||= buffer.size - offset
      Native.wgpuRenderPassEncoderSetVertexBuffer(@handle, slot, buffer.handle, offset, size)
    end

    def set_index_buffer(buffer, format, offset: 0, size: nil)
      size ||= buffer.size - offset
      Native.wgpuRenderPassEncoderSetIndexBuffer(@handle, buffer.handle, format, offset, size)
    end

    def draw(vertex_count, instance_count: 1, first_vertex: 0, first_instance: 0)
      Native.wgpuRenderPassEncoderDraw(@handle, vertex_count, instance_count, first_vertex, first_instance)
    end

    def draw_indexed(index_count, instance_count: 1, first_index: 0, base_vertex: 0, first_instance: 0)
      Native.wgpuRenderPassEncoderDrawIndexed(@handle, index_count, instance_count, first_index, base_vertex, first_instance)
    end

    def set_viewport(x, y, width, height, min_depth: 0.0, max_depth: 1.0)
      Native.wgpuRenderPassEncoderSetViewport(@handle, x, y, width, height, min_depth, max_depth)
    end

    def set_scissor_rect(x, y, width, height)
      Native.wgpuRenderPassEncoderSetScissorRect(@handle, x, y, width, height)
    end

    def set_blend_constant(r: 0.0, g: 0.0, b: 0.0, a: 1.0)
      color = Native::Color.new
      color[:r] = r
      color[:g] = g
      color[:b] = b
      color[:a] = a
      Native.wgpuRenderPassEncoderSetBlendConstant(@handle, color.to_ptr)
    end

    def set_stencil_reference(reference)
      Native.wgpuRenderPassEncoderSetStencilReference(@handle, reference)
    end

    def draw_indirect(buffer, offset: 0)
      Native.wgpuRenderPassEncoderDrawIndirect(@handle, buffer.handle, offset)
    end

    def draw_indexed_indirect(buffer, offset: 0)
      Native.wgpuRenderPassEncoderDrawIndexedIndirect(@handle, buffer.handle, offset)
    end

    def execute_bundles(bundles)
      bundle_handles = bundles.map(&:handle)
      bundles_ptr = FFI::MemoryPointer.new(:pointer, bundle_handles.size)
      bundles_ptr.write_array_of_pointer(bundle_handles)
      Native.wgpuRenderPassEncoderExecuteBundles(@handle, bundle_handles.size, bundles_ptr)
    end

    def begin_occlusion_query(query_index)
      Native.wgpuRenderPassEncoderBeginOcclusionQuery(@handle, query_index)
    end

    def end_occlusion_query
      Native.wgpuRenderPassEncoderEndOcclusionQuery(@handle)
    end

    def push_debug_group(label)
      label_view = Native::StringView.new
      label_ptr = FFI::MemoryPointer.from_string(label)
      label_view[:data] = label_ptr
      label_view[:length] = label.bytesize
      Native.wgpuRenderPassEncoderPushDebugGroup(@handle, label_view)
    end

    def pop_debug_group
      Native.wgpuRenderPassEncoderPopDebugGroup(@handle)
    end

    def insert_debug_marker(label)
      label_view = Native::StringView.new
      label_ptr = FFI::MemoryPointer.from_string(label)
      label_view[:data] = label_ptr
      label_view[:length] = label.bytesize
      Native.wgpuRenderPassEncoderInsertDebugMarker(@handle, label_view)
    end

    def end_pass
      Native.wgpuRenderPassEncoderEnd(@handle)
    end

    def end
      end_pass
    end

    def release
      return if @handle.null?
      Native.wgpuRenderPassEncoderRelease(@handle)
      @handle = FFI::Pointer::NULL
    end

    private

    def setup_label(desc, label)
      if label
        ptr = FFI::MemoryPointer.from_string(label)
        @pointers << ptr
        desc[:label][:data] = ptr
        desc[:label][:length] = label.bytesize
      else
        desc[:label][:data] = nil
        desc[:label][:length] = 0
      end
    end

    def setup_color_attachments(attachments)
      ptr = FFI::MemoryPointer.new(Native::RenderPassColorAttachment, attachments.size)
      @pointers << ptr

      attachments.each_with_index do |att, i|
        ca = Native::RenderPassColorAttachment.new(ptr + i * Native::RenderPassColorAttachment.size)
        ca[:next_in_chain] = nil
        ca[:view] = att[:view].handle
        ca[:depth_slice] = att[:depth_slice] || 0xFFFFFFFF
        ca[:resolve_target] = att[:resolve_target]&.handle
        ca[:load_op] = att[:load_op] || :clear
        ca[:store_op] = att[:store_op] || :store

        clear = att[:clear_value] || { r: 0.0, g: 0.0, b: 0.0, a: 1.0 }
        ca[:clear_value][:r] = clear[:r] || 0.0
        ca[:clear_value][:g] = clear[:g] || 0.0
        ca[:clear_value][:b] = clear[:b] || 0.0
        ca[:clear_value][:a] = clear[:a] || 1.0
      end

      ptr
    end

    def setup_depth_stencil_attachment(att)
      ds = Native::RenderPassDepthStencilAttachment.new
      @pointers << ds

      ds[:view] = att[:view].handle
      ds[:depth_load_op] = att[:depth_load_op] || :clear
      ds[:depth_store_op] = att[:depth_store_op] || :store
      ds[:depth_clear_value] = att[:depth_clear_value] || 1.0
      ds[:depth_read_only] = att[:depth_read_only] ? 1 : 0
      ds[:stencil_load_op] = att[:stencil_load_op] || :clear
      ds[:stencil_store_op] = att[:stencil_store_op] || :store
      ds[:stencil_clear_value] = att[:stencil_clear_value] || 0
      ds[:stencil_read_only] = att[:stencil_read_only] ? 1 : 0

      ds.to_ptr
    end
  end
end
