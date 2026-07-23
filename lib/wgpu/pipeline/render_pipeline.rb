# frozen_string_literal: true

module WGPU
  class RenderPipeline
    attr_reader :handle

    def initialize(device, label: nil, layout:, vertex:, primitive: {}, depth_stencil: nil, multisample: {}, fragment: nil)
      @device = device
      @pointers = []

      desc = Native::RenderPipelineDescriptor.new
      desc[:next_in_chain] = nil
      setup_label(desc, label)
      desc[:layout] = normalize_layout(layout)

      setup_vertex_state(desc[:vertex], vertex)
      setup_primitive_state(desc[:primitive], primitive)
      setup_multisample_state(desc[:multisample], multisample)

      if depth_stencil
        ds_ptr = setup_depth_stencil_state(depth_stencil)
        desc[:depth_stencil] = ds_ptr
      else
        desc[:depth_stencil] = nil
      end

      if fragment
        frag_ptr = setup_fragment_state(fragment)
        desc[:fragment] = frag_ptr
      else
        desc[:fragment] = nil
      end

      device.push_error_scope(:validation)
      @handle = Native.wgpuDeviceCreateRenderPipeline(device.handle, desc)
      error = device.pop_error_scope

      if @handle.null? || (error[:type] && error[:type] != :no_error)
        msg = error[:message] || "Failed to create render pipeline"
        raise PipelineError, msg
      end
    end

    def get_bind_group_layout(index)
      handle = Native.wgpuRenderPipelineGetBindGroupLayout(@handle, index)
      raise PipelineError, "Failed to get bind group layout at index #{index}" if handle.null?
      BindGroupLayout.from_handle(handle)
    end

    def release
      return if @handle.null?
      Native.wgpuRenderPipelineRelease(@handle)
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

    def setup_vertex_state(vertex_state, vertex)
      vertex_state[:next_in_chain] = nil
      vertex_state[:module] = vertex[:module].handle

      entry_point = vertex[:entry_point] || "main"
      entry_ptr = FFI::MemoryPointer.from_string(entry_point)
      @pointers << entry_ptr
      vertex_state[:entry_point][:data] = entry_ptr
      vertex_state[:entry_point][:length] = entry_point.bytesize

      vertex_state[:constant_count] = 0
      vertex_state[:constants] = nil
      setup_constants(vertex_state, vertex[:constants])

      buffers = vertex[:buffers] || []
      if buffers.empty?
        vertex_state[:buffer_count] = 0
        vertex_state[:buffers] = nil
      else
        buffer_layouts = setup_vertex_buffer_layouts(buffers)
        vertex_state[:buffer_count] = buffers.size
        vertex_state[:buffers] = buffer_layouts
      end
    end

    def setup_vertex_buffer_layouts(buffers)
      layouts_ptr = FFI::MemoryPointer.new(Native::VertexBufferLayout, buffers.size)
      @pointers << layouts_ptr

      buffers.each_with_index do |buf, i|
        layout = Native::VertexBufferLayout.new(layouts_ptr + (i * Native::VertexBufferLayout.size))
        layout[:step_mode] = buf[:step_mode] || :vertex
        layout[:array_stride] = buf[:array_stride]

        attrs = buf[:attributes] || []
        if attrs.empty?
          layout[:attribute_count] = 0
          layout[:attributes] = nil
        else
          attrs_ptr = FFI::MemoryPointer.new(Native::VertexAttribute, attrs.size)
          @pointers << attrs_ptr
          attrs.each_with_index do |attr, j|
            a = Native::VertexAttribute.new(attrs_ptr + (j * Native::VertexAttribute.size))
            a[:format] = attr[:format]
            a[:offset] = attr[:offset]
            a[:shader_location] = attr[:shader_location]
          end
          layout[:attribute_count] = attrs.size
          layout[:attributes] = attrs_ptr
        end
      end

      layouts_ptr
    end

    def setup_primitive_state(primitive_state, primitive)
      primitive_state[:next_in_chain] = nil
      primitive_state[:topology] = primitive[:topology] || :triangle_list
      primitive_state[:strip_index_format] = primitive[:strip_index_format] || :undefined
      primitive_state[:front_face] = primitive[:front_face] || :ccw
      primitive_state[:cull_mode] = primitive[:cull_mode] || :none
      primitive_state[:unclipped_depth] = primitive[:unclipped_depth] ? 1 : 0
    end

    def setup_multisample_state(multisample_state, multisample)
      multisample_state[:next_in_chain] = nil
      multisample_state[:count] = multisample[:count] || 1
      multisample_state[:mask] = multisample[:mask] || 0xFFFFFFFF
      multisample_state[:alpha_to_coverage_enabled] = multisample[:alpha_to_coverage_enabled] ? 1 : 0
    end

    def setup_depth_stencil_state(depth_stencil)
      ds = Native::DepthStencilState.new
      @pointers << ds
      ds[:next_in_chain] = nil
      ds[:format] = depth_stencil[:format]
      ds[:depth_write_enabled] = depth_stencil[:depth_write_enabled] ? 1 : 0
      ds[:depth_compare] = depth_stencil[:depth_compare] || :always

      setup_stencil_face(ds[:stencil_front], depth_stencil[:stencil_front] || {})
      setup_stencil_face(ds[:stencil_back], depth_stencil[:stencil_back] || {})

      ds[:stencil_read_mask] = depth_stencil[:stencil_read_mask] || 0xFFFFFFFF
      ds[:stencil_write_mask] = depth_stencil[:stencil_write_mask] || 0xFFFFFFFF
      ds[:depth_bias] = depth_stencil[:depth_bias] || 0
      ds[:depth_bias_slope_scale] = depth_stencil[:depth_bias_slope_scale] || 0.0
      ds[:depth_bias_clamp] = depth_stencil[:depth_bias_clamp] || 0.0

      ds.to_ptr
    end

    def setup_stencil_face(face, config)
      face[:compare] = config[:compare] || :always
      face[:fail_op] = config[:fail_op] || :keep
      face[:depth_fail_op] = config[:depth_fail_op] || :keep
      face[:pass_op] = config[:pass_op] || :keep
    end

    def setup_fragment_state(fragment)
      frag = Native::FragmentState.new
      @pointers << frag
      frag[:next_in_chain] = nil
      frag[:module] = fragment[:module].handle

      entry_point = fragment[:entry_point] || "main"
      entry_ptr = FFI::MemoryPointer.from_string(entry_point)
      @pointers << entry_ptr
      frag[:entry_point][:data] = entry_ptr
      frag[:entry_point][:length] = entry_point.bytesize

      frag[:constant_count] = 0
      frag[:constants] = nil
      setup_constants(frag, fragment[:constants])

      targets = fragment[:targets] || []
      if targets.empty?
        frag[:target_count] = 0
        frag[:targets] = nil
      else
        targets_ptr = setup_color_targets(targets)
        frag[:target_count] = targets.size
        frag[:targets] = targets_ptr
      end

      frag.to_ptr
    end

    def setup_color_targets(targets)
      targets_ptr = FFI::MemoryPointer.new(Native::ColorTargetState, targets.size)
      @pointers << targets_ptr

      targets.each_with_index do |target, i|
        ct = Native::ColorTargetState.new(targets_ptr + (i * Native::ColorTargetState.size))
        ct[:next_in_chain] = nil
        ct[:format] = target[:format]
        ct[:write_mask] = normalize_write_mask(target[:write_mask])

        if target[:blend]
          blend_ptr = setup_blend_state(target[:blend])
          ct[:blend] = blend_ptr
        else
          ct[:blend] = nil
        end
      end

      targets_ptr
    end

    def setup_blend_state(blend)
      bs = Native::BlendState.new
      @pointers << bs

      color = blend[:color] || {}
      bs[:color][:operation] = color[:operation] || :add
      bs[:color][:src_factor] = color[:src_factor] || :one
      bs[:color][:dst_factor] = color[:dst_factor] || :zero

      alpha = blend[:alpha] || {}
      bs[:alpha][:operation] = alpha[:operation] || :add
      bs[:alpha][:src_factor] = alpha[:src_factor] || :one
      bs[:alpha][:dst_factor] = alpha[:dst_factor] || :zero

      bs.to_ptr
    end

    def normalize_write_mask(mask)
      case mask
      when nil
        Native::ColorWriteMask[:all]
      when Integer
        mask
      when Symbol
        Native::ColorWriteMask[mask]
      when Array
        mask.reduce(0) { |acc, m| acc | Native::ColorWriteMask[m] }
      else
        raise ArgumentError, "Invalid write_mask: #{mask}"
      end
    end

    def normalize_layout(layout)
      return nil if layout.nil? || layout == :auto || layout == "auto"
      layout.handle
    end

    def setup_constants(stage_state, constants)
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

      stage_state[:constant_count] = constants.size
      stage_state[:constants] = constants_ptr
    end
  end
end
