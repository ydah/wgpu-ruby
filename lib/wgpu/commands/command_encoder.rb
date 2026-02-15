# frozen_string_literal: true

module WGPU
  class CommandEncoder
    attr_reader :handle

    def initialize(device, label: nil)
      @device = device
      @finished = false

      desc = Native::CommandEncoderDescriptor.new
      desc[:next_in_chain] = nil
      if label
        label_ptr = FFI::MemoryPointer.from_string(label)
        desc[:label][:data] = label_ptr
        desc[:label][:length] = label.bytesize
      else
        desc[:label][:data] = nil
        desc[:label][:length] = 0
      end

      @handle = Native.wgpuDeviceCreateCommandEncoder(device.handle, desc)
      raise CommandError, "Failed to create command encoder" if @handle.null?
    end

    def begin_compute_pass(label: nil, timestamp_writes: nil)
      raise CommandError, "Encoder already finished" if @finished
      ComputePass.new(self, label: label, timestamp_writes: timestamp_writes)
    end

    def begin_render_pass(color_attachments:, depth_stencil_attachment: nil, occlusion_query_set: nil, timestamp_writes: nil, max_draw_count: nil, label: nil)
      raise CommandError, "Encoder already finished" if @finished
      RenderPass.new(self,
        color_attachments: color_attachments,
        depth_stencil_attachment: depth_stencil_attachment,
        occlusion_query_set: occlusion_query_set,
        timestamp_writes: timestamp_writes,
        max_draw_count: max_draw_count,
        label: label
      )
    end

    def copy_buffer_to_buffer(source:, source_offset: 0, destination:, destination_offset: 0, size:)
      raise CommandError, "Encoder already finished" if @finished
      Native.wgpuCommandEncoderCopyBufferToBuffer(
        @handle,
        source.handle, source_offset,
        destination.handle, destination_offset,
        size
      )
    end

    def copy_buffer_to_texture(source:, destination:, copy_size:)
      raise CommandError, "Encoder already finished" if @finished

      size = Native::Extent3D.new
      size[:width] = copy_size[:width] || copy_size[0]
      size[:height] = copy_size[:height] || copy_size[1] || 1
      size[:depth_or_array_layers] = copy_size[:depth_or_array_layers] || copy_size[2] || 1

      src = Native::ImageCopyBuffer.new
      src[:layout][:offset] = source[:offset] || 0
      src[:layout][:bytes_per_row] = source[:bytes_per_row]
      src[:layout][:rows_per_image] = source[:rows_per_image] || size[:height]
      src[:buffer] = source[:buffer].handle

      dst = Native::ImageCopyTexture.new
      dst[:texture] = destination[:texture].handle
      dst[:mip_level] = destination[:mip_level] || 0
      dst[:origin][:x] = destination.dig(:origin, :x) || 0
      dst[:origin][:y] = destination.dig(:origin, :y) || 0
      dst[:origin][:z] = destination.dig(:origin, :z) || 0
      dst[:aspect] = destination[:aspect] || :all

      Native.wgpuCommandEncoderCopyBufferToTexture(@handle, src, dst, size)
    end

    def copy_texture_to_buffer(source:, destination:, copy_size:)
      raise CommandError, "Encoder already finished" if @finished

      size = Native::Extent3D.new
      size[:width] = copy_size[:width] || copy_size[0]
      size[:height] = copy_size[:height] || copy_size[1] || 1
      size[:depth_or_array_layers] = copy_size[:depth_or_array_layers] || copy_size[2] || 1

      src = Native::ImageCopyTexture.new
      src[:texture] = source[:texture].handle
      src[:mip_level] = source[:mip_level] || 0
      src[:origin][:x] = source.dig(:origin, :x) || 0
      src[:origin][:y] = source.dig(:origin, :y) || 0
      src[:origin][:z] = source.dig(:origin, :z) || 0
      src[:aspect] = source[:aspect] || :all

      dst = Native::ImageCopyBuffer.new
      dst[:layout][:offset] = destination[:offset] || 0
      dst[:layout][:bytes_per_row] = destination[:bytes_per_row]
      dst[:layout][:rows_per_image] = destination[:rows_per_image] || size[:height]
      dst[:buffer] = destination[:buffer].handle

      Native.wgpuCommandEncoderCopyTextureToBuffer(@handle, src, dst, size)
    end

    def copy_texture_to_texture(source:, destination:, copy_size:)
      raise CommandError, "Encoder already finished" if @finished

      src = Native::ImageCopyTexture.new
      src[:texture] = source[:texture].handle
      src[:mip_level] = source[:mip_level] || 0
      src[:origin][:x] = source.dig(:origin, :x) || 0
      src[:origin][:y] = source.dig(:origin, :y) || 0
      src[:origin][:z] = source.dig(:origin, :z) || 0
      src[:aspect] = source[:aspect] || :all

      dst = Native::ImageCopyTexture.new
      dst[:texture] = destination[:texture].handle
      dst[:mip_level] = destination[:mip_level] || 0
      dst[:origin][:x] = destination.dig(:origin, :x) || 0
      dst[:origin][:y] = destination.dig(:origin, :y) || 0
      dst[:origin][:z] = destination.dig(:origin, :z) || 0
      dst[:aspect] = destination[:aspect] || :all

      size = Native::Extent3D.new
      size[:width] = copy_size[:width] || copy_size[0]
      size[:height] = copy_size[:height] || copy_size[1] || 1
      size[:depth_or_array_layers] = copy_size[:depth_or_array_layers] || copy_size[2] || 1

      Native.wgpuCommandEncoderCopyTextureToTexture(@handle, src, dst, size)
    end

    def resolve_query_set(query_set:, first_query:, query_count:, destination:, destination_offset:)
      raise CommandError, "Encoder already finished" if @finished
      Native.wgpuCommandEncoderResolveQuerySet(
        @handle,
        query_set.handle,
        first_query,
        query_count,
        destination.handle,
        destination_offset
      )
    end

    def clear_buffer(buffer, offset: 0, size: nil)
      raise CommandError, "Encoder already finished" if @finished
      size ||= buffer.size - offset
      Native.wgpuCommandEncoderClearBuffer(@handle, buffer.handle, offset, size)
    end

    def write_timestamp(query_set, query_index)
      raise CommandError, "Encoder already finished" if @finished
      Native.wgpuCommandEncoderWriteTimestamp(@handle, query_set.handle, query_index)
    end

    def push_debug_group(label)
      raise CommandError, "Encoder already finished" if @finished
      label_view = Native::StringView.new
      label_ptr = FFI::MemoryPointer.from_string(label)
      label_view[:data] = label_ptr
      label_view[:length] = label.bytesize
      Native.wgpuCommandEncoderPushDebugGroup(@handle, label_view)
    end

    def pop_debug_group
      raise CommandError, "Encoder already finished" if @finished
      Native.wgpuCommandEncoderPopDebugGroup(@handle)
    end

    def insert_debug_marker(label)
      raise CommandError, "Encoder already finished" if @finished
      label_view = Native::StringView.new
      label_ptr = FFI::MemoryPointer.from_string(label)
      label_view[:data] = label_ptr
      label_view[:length] = label.bytesize
      Native.wgpuCommandEncoderInsertDebugMarker(@handle, label_view)
    end

    def finish(label: nil)
      raise CommandError, "Encoder already finished" if @finished
      @finished = true

      desc = nil
      if label
        desc = Native::CommandBufferDescriptor.new
        desc[:next_in_chain] = nil
        label_ptr = FFI::MemoryPointer.from_string(label)
        desc[:label][:data] = label_ptr
        desc[:label][:length] = label.bytesize
      end

      buffer_handle = Native.wgpuCommandEncoderFinish(@handle, desc)
      raise CommandError, "Failed to finish command encoder" if buffer_handle.null?

      CommandBuffer.new(buffer_handle)
    end

    def release
      return if @handle.null?
      Native.wgpuCommandEncoderRelease(@handle)
      @handle = FFI::Pointer::NULL
    end
  end
end
