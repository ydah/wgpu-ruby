# frozen_string_literal: true

module WGPU
  class ComputePass
    attr_reader :handle

    # Begins a compute pass owned by the command encoder.
    # @param encoder [CommandEncoder] owning encoder
    # @param label [String, nil] optional debug label
    # @param timestamp_writes [Hash, nil] beginning and ending timestamp query settings
    # @raise [CommandError] if the native pass cannot be created
    def initialize(encoder, label: nil, timestamp_writes: nil)
      @encoder = encoder
      @ended = false
      desc = Native::ComputePassDescriptor.new
      desc[:next_in_chain] = nil
      if label
        label_ptr = FFI::MemoryPointer.from_string(label)
        desc[:label][:data] = label_ptr
        desc[:label][:length] = label.bytesize
      else
        desc[:label][:data] = nil
        desc[:label][:length] = 0
      end
      @timestamp_writes = nil
      if timestamp_writes
        @timestamp_writes = Native::ComputePassTimestampWrites.new
        @timestamp_writes[:query_set] = timestamp_writes.fetch(:query_set).handle
        @timestamp_writes[:beginning_of_pass_write_index] = timestamp_writes[:beginning_of_pass_write_index] || 0xFFFFFFFF
        @timestamp_writes[:end_of_pass_write_index] = timestamp_writes[:end_of_pass_write_index] || 0xFFFFFFFF
        desc[:timestamp_writes] = @timestamp_writes.to_ptr
      else
        desc[:timestamp_writes] = nil
      end

      @handle = Native.wgpuCommandEncoderBeginComputePass(encoder.handle, desc)
      raise CommandError, "Failed to begin compute pass" if @handle.null?
    end

    # Selects the compute pipeline used by subsequent dispatches.
    # @param pipeline [ComputePipeline] pipeline to bind
    # @return [void]
    def set_pipeline(pipeline)
      Native.wgpuComputePassEncoderSetPipeline(@handle, pipeline.handle)
    end

    # Binds a resource group for subsequent dispatches.
    # @param index [Integer] bind group index
    # @param bind_group [BindGroup] group to bind
    # @param dynamic_offsets [Array<Integer>] dynamic buffer offsets
    # @return [void]
    def set_bind_group(index, bind_group, dynamic_offsets: [])
      if dynamic_offsets.empty?
        Native.wgpuComputePassEncoderSetBindGroup(@handle, index, bind_group.handle, 0, nil)
      else
        offsets_ptr = FFI::MemoryPointer.new(:uint32, dynamic_offsets.size)
        offsets_ptr.write_array_of_uint32(dynamic_offsets)
        Native.wgpuComputePassEncoderSetBindGroup(@handle, index, bind_group.handle, dynamic_offsets.size, offsets_ptr)
      end
    end

    # Dispatches a three-dimensional compute workgroup grid.
    # @param x [Integer] workgroup count on the x axis
    # @param y [Integer] workgroup count on the y axis
    # @param z [Integer] workgroup count on the z axis
    # @return [void]
    def dispatch_workgroups(x, y = 1, z = 1)
      Native.wgpuComputePassEncoderDispatchWorkgroups(@handle, x, y, z)
    end

    # Dispatches workgroups using arguments read from a buffer.
    # @param buffer [Buffer] indirect argument buffer
    # @param offset [Integer] byte offset of the arguments
    # @return [void]
    def dispatch_workgroups_indirect(buffer, offset: 0)
      Native.wgpuComputePassEncoderDispatchWorkgroupsIndirect(@handle, buffer.handle, offset)
    end

    # Starts a labeled group in GPU debugging tools.
    #
    # @param label [String] group label
    # @return [void]
    def push_debug_group(label)
      label_view = Native::StringView.new
      label_ptr = FFI::MemoryPointer.from_string(label)
      label_view[:data] = label_ptr
      label_view[:length] = label.bytesize
      Native.wgpuComputePassEncoderPushDebugGroup(@handle, label_view)
    end

    # Ends the most recently pushed debug group.
    #
    # @return [void]
    def pop_debug_group
      Native.wgpuComputePassEncoderPopDebugGroup(@handle)
    end

    # Inserts a labeled point in GPU debugging tools.
    #
    # @param label [String] marker label
    # @return [void]
    def insert_debug_marker(label)
      label_view = Native::StringView.new
      label_ptr = FFI::MemoryPointer.from_string(label)
      label_view[:data] = label_ptr
      label_view[:length] = label.bytesize
      Native.wgpuComputePassEncoderInsertDebugMarker(@handle, label_view)
    end

    # Ends the pass if it has not already ended.
    # @return [void]
    def end_pass
      return if @ended

      Native.wgpuComputePassEncoderEnd(@handle)
      @ended = true
      @encoder.send(:pass_ended, self)
    end

    # Ends the pass.
    # @return [void]
    def end
      end_pass
    end

    # Reports whether the pass has ended.
    # @return [Boolean]
    def ended?
      @ended
    end

    # Releases the native compute pass encoder handle.
    #
    # Calling this method more than once has no effect.
    # @return [void]
    def release
      return if @handle.null?
      Native.wgpuComputePassEncoderRelease(@handle)
      @handle = FFI::Pointer::NULL
    end
  end
end
