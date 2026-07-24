# frozen_string_literal: true

module WGPU
  class CommandEncoder
    attr_reader :handle

    # Creates an encoder for commands submitted to a device queue.
    # @param device [Device] owning device
    # @param label [String, nil] optional debug label
    # @raise [CommandError] if the native encoder cannot be created
    def initialize(device, label: nil)
      @device = device
      @finished = false
      @active_pass = nil

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

    # Begins a compute pass, optionally yielding it for scoped recording.
    # @param label [String, nil] optional debug label
    # @param timestamp_writes [Hash, nil] timestamp query settings
    # @yieldparam pass [ComputePass] newly created pass
    # @return [ComputePass, Object] pass without a block, otherwise the block result
    def begin_compute_pass(label: nil, timestamp_writes: nil)
      ensure_can_begin_pass!
      pass = ComputePass.new(self, label: label, timestamp_writes: timestamp_writes)
      @active_pass = pass
      return pass unless block_given?

      begin
        yield pass
      ensure
        begin
          pass.end_pass unless pass.ended?
        ensure
          pass.release
          pass_ended(pass)
        end
      end
    end

    # Begins a render pass, optionally yielding it for scoped recording.
    # @param color_attachments [Array<Hash>] color attachment descriptors
    # @yieldparam pass [RenderPass] newly created pass
    # @return [RenderPass, Object] pass without a block, otherwise the block result
    def begin_render_pass(color_attachments:, depth_stencil_attachment: nil, occlusion_query_set: nil, timestamp_writes: nil, max_draw_count: nil, label: nil)
      ensure_can_begin_pass!
      pass = RenderPass.new(self,
        color_attachments: color_attachments,
        depth_stencil_attachment: depth_stencil_attachment,
        occlusion_query_set: occlusion_query_set,
        timestamp_writes: timestamp_writes,
        max_draw_count: max_draw_count,
        label: label
      )
      @active_pass = pass
      return pass unless block_given?

      begin
        yield pass
      ensure
        begin
          pass.end_pass unless pass.ended?
        ensure
          pass.release
          pass_ended(pass)
        end
      end
    end

    # Copies bytes between buffers.
    # @return [void]
    def copy_buffer_to_buffer(source:, source_offset: 0, destination:, destination_offset: 0, size:)
      raise CommandError, "Encoder already finished" if @finished
      Native.wgpuCommandEncoderCopyBufferToBuffer(
        @handle,
        source.handle, source_offset,
        destination.handle, destination_offset,
        size
      )
    end

    # Copies buffer data into a texture region.
    # @param source [Hash] buffer and layout descriptor
    # @param destination [Hash] texture and origin descriptor
    # @param copy_size [Hash, Array] extent to copy
    # @return [void]
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
      dst[:aspect] = Native::EnumHelper.coerce(
        Native::TextureAspect,
        destination[:aspect] || :all,
        name: "texture aspect"
      )

      Native.wgpuCommandEncoderCopyBufferToTexture(@handle, src, dst, size)
    end

    # Copies a texture region into a buffer.
    # @param source [Hash] texture and origin descriptor
    # @param destination [Hash] buffer and layout descriptor
    # @param copy_size [Hash, Array] extent to copy
    # @return [void]
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
      src[:aspect] = Native::EnumHelper.coerce(
        Native::TextureAspect,
        source[:aspect] || :all,
        name: "texture aspect"
      )

      dst = Native::ImageCopyBuffer.new
      dst[:layout][:offset] = destination[:offset] || 0
      dst[:layout][:bytes_per_row] = destination[:bytes_per_row]
      dst[:layout][:rows_per_image] = destination[:rows_per_image] || size[:height]
      dst[:buffer] = destination[:buffer].handle

      Native.wgpuCommandEncoderCopyTextureToBuffer(@handle, src, dst, size)
    end

    # Copies one texture region into another texture.
    # @param source [Hash] source texture and origin descriptor
    # @param destination [Hash] destination texture and origin descriptor
    # @param copy_size [Hash, Array] extent to copy
    # @return [void]
    def copy_texture_to_texture(source:, destination:, copy_size:)
      raise CommandError, "Encoder already finished" if @finished

      src = Native::ImageCopyTexture.new
      src[:texture] = source[:texture].handle
      src[:mip_level] = source[:mip_level] || 0
      src[:origin][:x] = source.dig(:origin, :x) || 0
      src[:origin][:y] = source.dig(:origin, :y) || 0
      src[:origin][:z] = source.dig(:origin, :z) || 0
      src[:aspect] = Native::EnumHelper.coerce(
        Native::TextureAspect,
        source[:aspect] || :all,
        name: "source texture aspect"
      )

      dst = Native::ImageCopyTexture.new
      dst[:texture] = destination[:texture].handle
      dst[:mip_level] = destination[:mip_level] || 0
      dst[:origin][:x] = destination.dig(:origin, :x) || 0
      dst[:origin][:y] = destination.dig(:origin, :y) || 0
      dst[:origin][:z] = destination.dig(:origin, :z) || 0
      dst[:aspect] = Native::EnumHelper.coerce(
        Native::TextureAspect,
        destination[:aspect] || :all,
        name: "destination texture aspect"
      )

      size = Native::Extent3D.new
      size[:width] = copy_size[:width] || copy_size[0]
      size[:height] = copy_size[:height] || copy_size[1] || 1
      size[:depth_or_array_layers] = copy_size[:depth_or_array_layers] || copy_size[2] || 1

      Native.wgpuCommandEncoderCopyTextureToTexture(@handle, src, dst, size)
    end

    # Resolves query results into a destination buffer.
    # @return [void]
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

    # Clears a byte range in a buffer to zero.
    # @param buffer [Buffer] buffer to clear
    # @param offset [Integer] first byte to clear
    # @param size [Integer, nil] number of bytes to clear
    # @return [void]
    def clear_buffer(buffer, offset: 0, size: nil)
      raise CommandError, "Encoder already finished" if @finished
      size ||= buffer.size - offset
      Native.wgpuCommandEncoderClearBuffer(@handle, buffer.handle, offset, size)
    end

    # Writes a GPU timestamp to a query set.
    # @param query_set [QuerySet] timestamp query set
    # @param query_index [Integer] destination query index
    # @return [void]
    def write_timestamp(query_set, query_index)
      raise CommandError, "Encoder already finished" if @finished
      Native.wgpuCommandEncoderWriteTimestamp(@handle, query_set.handle, query_index)
    end

    # Starts a labeled group in GPU debugging tools.
    # @param label [String] group label
    # @return [void]
    def push_debug_group(label)
      raise CommandError, "Encoder already finished" if @finished
      label_view = Native::StringView.new
      label_ptr = FFI::MemoryPointer.from_string(label)
      label_view[:data] = label_ptr
      label_view[:length] = label.bytesize
      Native.wgpuCommandEncoderPushDebugGroup(@handle, label_view)
    end

    # Ends the most recently pushed debug group.
    # @return [void]
    def pop_debug_group
      raise CommandError, "Encoder already finished" if @finished
      Native.wgpuCommandEncoderPopDebugGroup(@handle)
    end

    # Inserts a labeled point in GPU debugging tools.
    # @param label [String] marker label
    # @return [void]
    def insert_debug_marker(label)
      raise CommandError, "Encoder already finished" if @finished
      label_view = Native::StringView.new
      label_ptr = FFI::MemoryPointer.from_string(label)
      label_view[:data] = label_ptr
      label_view[:length] = label.bytesize
      Native.wgpuCommandEncoderInsertDebugMarker(@handle, label_view)
    end

    # Finishes recording and returns a command buffer.
    # @param label [String, nil] optional command buffer label
    # @return [CommandBuffer]
    # @raise [CommandError] if the encoder is finished, has an active pass, or native creation fails
    def finish(label: nil)
      raise CommandError, "Encoder already finished" if @finished
      if @active_pass && !@active_pass.ended?
        raise CommandError, "Cannot finish command encoder while a pass is active"
      end
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

      CommandBuffer.new(buffer_handle, device: @device)
    end

    # Releases the native command encoder handle.
    #
    # Calling this method more than once has no effect.
    # @return [void]
    def release
      return if @handle.null?
      Native.wgpuCommandEncoderRelease(@handle)
      @handle = FFI::Pointer::NULL
    end

    private

    def ensure_can_begin_pass!
      raise CommandError, "Encoder already finished" if @finished
      raise CommandError, "A command pass is already active" if @active_pass && !@active_pass.ended?
    end

    def pass_ended(pass)
      @active_pass = nil if @active_pass.equal?(pass)
    end
  end
end
