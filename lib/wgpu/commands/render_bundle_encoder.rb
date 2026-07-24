# frozen_string_literal: true

module WGPU
  class RenderBundleEncoder
    attr_reader :handle

    # Creates an encoder for reusable render commands.
    # @param device [Device] owning device
    # @param color_formats [Array<Symbol, Integer>] color attachment formats
    # @param depth_stencil_format [Symbol, Integer, nil] optional depth/stencil format
    # @param sample_count [Integer] multisample count
    # @param depth_read_only [Boolean] whether depth writes are disabled
    # @param stencil_read_only [Boolean] whether stencil writes are disabled
    # @param label [String, nil] optional debug label
    # @raise [RenderBundleError] if the native encoder cannot be created
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

      formats = Array(color_formats).map do |format|
        Native::EnumHelper.coerce(Native::TextureFormat, format, name: "color format")
      end
      @formats_ptr = FFI::MemoryPointer.new(:uint32, formats.size)
      @formats_ptr.write_array_of_uint32(formats)
      desc[:color_format_count] = formats.size
      desc[:color_formats] = @formats_ptr

      desc[:depth_stencil_format] = Native::EnumHelper.coerce(
        Native::TextureFormat,
        depth_stencil_format || :undefined,
        name: "depth stencil format"
      )
      desc[:sample_count] = sample_count
      desc[:depth_read_only] = depth_read_only ? 1 : 0
      desc[:stencil_read_only] = stencil_read_only ? 1 : 0

      @handle = Native.wgpuDeviceCreateRenderBundleEncoder(device.handle, desc)
      raise RenderBundleError, "Failed to create render bundle encoder" if @handle.null?
    end

    # Selects the pipeline used by subsequent bundle draws.
    # @param pipeline [RenderPipeline] pipeline to bind
    # @raise [RenderBundleError] if the encoder is finished
    # @return [void]
    def set_pipeline(pipeline)
      raise RenderBundleError, "Encoder already finished" if @finished

      Native.wgpuRenderBundleEncoderSetPipeline(@handle, pipeline.handle)
    end

    # Binds a resource group for subsequent bundle draws.
    # @param index [Integer] bind group index
    # @param bind_group [BindGroup] group to bind
    # @param dynamic_offsets [Array<Integer>, nil] dynamic buffer offsets
    # @return [void]
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

    # Binds a vertex buffer to a slot.
    # @param slot [Integer] vertex buffer slot
    # @param buffer [Buffer] vertex data buffer
    # @return [void]
    def set_vertex_buffer(slot, buffer, offset: 0, size: nil)
      raise RenderBundleError, "Encoder already finished" if @finished

      size ||= buffer.size - offset
      Native.wgpuRenderBundleEncoderSetVertexBuffer(@handle, slot, buffer.handle, offset, size)
    end

    # Binds an index buffer for indexed bundle draws.
    # @param buffer [Buffer] index data buffer
    # @param format [Symbol, Integer] index element format
    # @return [void]
    def set_index_buffer(buffer, format: :uint32, offset: 0, size: nil)
      raise RenderBundleError, "Encoder already finished" if @finished

      size ||= buffer.size - offset
      format_value = Native::EnumHelper.coerce(Native::IndexFormat, format, name: "index format")
      Native.wgpuRenderBundleEncoderSetIndexBuffer(@handle, buffer.handle, format_value, offset, size)
    end

    # Records a non-indexed draw in the bundle.
    # @return [void]
    def draw(vertex_count, instance_count: 1, first_vertex: 0, first_instance: 0)
      raise RenderBundleError, "Encoder already finished" if @finished

      Native.wgpuRenderBundleEncoderDraw(@handle, vertex_count, instance_count, first_vertex, first_instance)
    end

    # Records an indexed draw in the bundle.
    # @return [void]
    def draw_indexed(index_count, instance_count: 1, first_index: 0, base_vertex: 0, first_instance: 0)
      raise RenderBundleError, "Encoder already finished" if @finished

      Native.wgpuRenderBundleEncoderDrawIndexed(@handle, index_count, instance_count, first_index, base_vertex, first_instance)
    end

    # Records a non-indexed draw using buffer arguments.
    # @param buffer [Buffer] indirect argument buffer
    # @param offset [Integer] byte offset of the arguments
    # @return [void]
    def draw_indirect(buffer, offset: 0)
      raise RenderBundleError, "Encoder already finished" if @finished

      Native.wgpuRenderBundleEncoderDrawIndirect(@handle, buffer.handle, offset)
    end

    # Records an indexed draw using buffer arguments.
    # @param buffer [Buffer] indirect argument buffer
    # @param offset [Integer] byte offset of the arguments
    # @return [void]
    def draw_indexed_indirect(buffer, offset: 0)
      raise RenderBundleError, "Encoder already finished" if @finished

      Native.wgpuRenderBundleEncoderDrawIndexedIndirect(@handle, buffer.handle, offset)
    end

    # Starts a labeled group in GPU debugging tools.
    # @param label [String] group label
    # @return [void]
    def push_debug_group(label)
      raise RenderBundleError, "Encoder already finished" if @finished

      label_view = Native::StringView.new
      label_ptr = FFI::MemoryPointer.from_string(label)
      label_view[:data] = label_ptr
      label_view[:length] = label.bytesize
      Native.wgpuRenderBundleEncoderPushDebugGroup(@handle, label_view)
    end

    # Ends the most recently pushed debug group.
    # @return [void]
    def pop_debug_group
      raise RenderBundleError, "Encoder already finished" if @finished

      Native.wgpuRenderBundleEncoderPopDebugGroup(@handle)
    end

    # Inserts a labeled point in GPU debugging tools.
    # @param label [String] marker label
    # @return [void]
    def insert_debug_marker(label)
      raise RenderBundleError, "Encoder already finished" if @finished

      label_view = Native::StringView.new
      label_ptr = FFI::MemoryPointer.from_string(label)
      label_view[:data] = label_ptr
      label_view[:length] = label.bytesize
      Native.wgpuRenderBundleEncoderInsertDebugMarker(@handle, label_view)
    end

    # Finishes recording and creates an immutable render bundle.
    # @param label [String, nil] optional bundle label
    # @return [RenderBundle]
    # @raise [RenderBundleError] if already finished or native creation fails
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

      RenderBundle.new(bundle_handle, device: @device)
    end

    # Releases the native render bundle encoder handle.
    #
    # Calling this method more than once has no effect.
    # @return [void]
    def release
      return if @handle.null?

      Native.wgpuRenderBundleEncoderRelease(@handle)
      @handle = FFI::Pointer::NULL
    end
  end
end
