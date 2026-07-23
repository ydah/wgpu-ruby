# frozen_string_literal: true

module WGPU
  class RenderPipeline
    attr_reader :handle

    def initialize(device, label: nil, layout:, vertex:, primitive: {}, depth_stencil: nil, multisample: {}, fragment: nil)
      @device = device
      desc, @pointers = build_descriptor(
        label:,
        layout:,
        vertex:,
        primitive:,
        depth_stencil:,
        multisample:,
        fragment:
      )

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

    def build_descriptor(label:, layout:, vertex:, primitive:, depth_stencil:, multisample:, fragment:)
      @pointers = []
      desc = Native::RenderPipelineDescriptor.new
      desc[:next_in_chain] = nil
      DescriptorHelpers.set_label(desc, label, keepalive: @pointers)
      desc[:layout] = normalize_layout(layout)

      setup_vertex_state(desc[:vertex], vertex)
      setup_primitive_state(desc[:primitive], primitive)
      setup_multisample_state(desc[:multisample], multisample)
      desc[:depth_stencil] = depth_stencil ? setup_depth_stencil_state(depth_stencil) : nil
      desc[:fragment] = fragment ? setup_fragment_state(fragment) : nil

      [desc, @pointers]
    end

    def setup_vertex_state(vertex_state, vertex)
      DescriptorHelpers.validate_keys!(
        vertex,
        allowed: %i[module entry_point constants buffers],
        required: [:module],
        context: "render pipeline vertex descriptor"
      )
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
        DescriptorHelpers.validate_keys!(
          buf,
          allowed: %i[array_stride step_mode attributes],
          required: [:array_stride],
          context: "vertex buffer layout"
        )
        layout = Native::VertexBufferLayout.new(layouts_ptr + (i * Native::VertexBufferLayout.size))
        layout[:step_mode] = Native::EnumHelper.coerce(
          Native::VertexStepMode,
          buf[:step_mode] || :vertex,
          name: "vertex step mode"
        )
        layout[:array_stride] = buf[:array_stride]

        attrs = buf[:attributes] || []
        if attrs.empty?
          layout[:attribute_count] = 0
          layout[:attributes] = nil
        else
          attrs_ptr = FFI::MemoryPointer.new(Native::VertexAttribute, attrs.size)
          @pointers << attrs_ptr
          attrs.each_with_index do |attr, j|
            DescriptorHelpers.validate_keys!(
              attr,
              allowed: %i[format offset shader_location],
              required: %i[format offset shader_location],
              context: "vertex attribute"
            )
            a = Native::VertexAttribute.new(attrs_ptr + (j * Native::VertexAttribute.size))
            a[:format] = Native::EnumHelper.coerce(
              Native::VertexFormat,
              attr[:format],
              name: "vertex format"
            )
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
      DescriptorHelpers.validate_keys!(
        primitive,
        allowed: %i[topology strip_index_format front_face cull_mode unclipped_depth],
        context: "primitive state"
      )
      primitive_state[:next_in_chain] = nil
      primitive_state[:topology] = Native::EnumHelper.coerce(
        Native::PrimitiveTopology,
        primitive[:topology] || :triangle_list,
        name: "primitive topology"
      )
      primitive_state[:strip_index_format] = Native::EnumHelper.coerce(
        Native::IndexFormat,
        primitive[:strip_index_format] || :undefined,
        name: "strip index format"
      )
      primitive_state[:front_face] = Native::EnumHelper.coerce(
        Native::FrontFace,
        primitive[:front_face] || :ccw,
        name: "front face"
      )
      primitive_state[:cull_mode] = Native::EnumHelper.coerce(
        Native::CullMode,
        primitive[:cull_mode] || :none,
        name: "cull mode"
      )
      primitive_state[:unclipped_depth] = primitive[:unclipped_depth] ? 1 : 0
    end

    def setup_multisample_state(multisample_state, multisample)
      DescriptorHelpers.validate_keys!(
        multisample,
        allowed: %i[count mask alpha_to_coverage_enabled],
        context: "multisample state"
      )
      multisample_state[:next_in_chain] = nil
      multisample_state[:count] = multisample[:count] || 1
      multisample_state[:mask] = multisample[:mask] || 0xFFFFFFFF
      multisample_state[:alpha_to_coverage_enabled] = multisample[:alpha_to_coverage_enabled] ? 1 : 0
    end

    def setup_depth_stencil_state(depth_stencil)
      DescriptorHelpers.validate_keys!(
        depth_stencil,
        allowed: %i[
          format depth_write_enabled depth_compare stencil_front stencil_back
          stencil_read_mask stencil_write_mask depth_bias depth_bias_slope_scale depth_bias_clamp
        ],
        required: [:format],
        context: "depth stencil state"
      )
      ds = Native::DepthStencilState.new
      @pointers << ds
      ds[:next_in_chain] = nil
      ds[:format] = Native::EnumHelper.coerce(
        Native::TextureFormat,
        depth_stencil[:format],
        name: "depth stencil format"
      )
      ds[:depth_write_enabled] = depth_stencil[:depth_write_enabled] ? 1 : 0
      ds[:depth_compare] = Native::EnumHelper.coerce(
        Native::CompareFunction,
        depth_stencil[:depth_compare] || :always,
        name: "depth compare function"
      )

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
      DescriptorHelpers.validate_keys!(
        config,
        allowed: %i[compare fail_op depth_fail_op pass_op],
        context: "stencil face state"
      )
      face[:compare] = Native::EnumHelper.coerce(
        Native::CompareFunction,
        config[:compare] || :always,
        name: "stencil compare function"
      )
      face[:fail_op] = Native::EnumHelper.coerce(
        Native::StencilOperation,
        config[:fail_op] || :keep,
        name: "stencil fail operation"
      )
      face[:depth_fail_op] = Native::EnumHelper.coerce(
        Native::StencilOperation,
        config[:depth_fail_op] || :keep,
        name: "stencil depth fail operation"
      )
      face[:pass_op] = Native::EnumHelper.coerce(
        Native::StencilOperation,
        config[:pass_op] || :keep,
        name: "stencil pass operation"
      )
    end

    def setup_fragment_state(fragment)
      DescriptorHelpers.validate_keys!(
        fragment,
        allowed: %i[module entry_point constants targets],
        required: [:module],
        context: "render pipeline fragment descriptor"
      )
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
        DescriptorHelpers.validate_keys!(
          target,
          allowed: %i[format blend write_mask],
          required: [:format],
          context: "color target state"
        )
        ct = Native::ColorTargetState.new(targets_ptr + (i * Native::ColorTargetState.size))
        ct[:next_in_chain] = nil
        ct[:format] = Native::EnumHelper.coerce(
          Native::TextureFormat,
          target[:format],
          name: "color target format"
        )
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
      DescriptorHelpers.validate_keys!(
        blend,
        allowed: %i[color alpha],
        context: "blend state"
      )
      bs = Native::BlendState.new
      @pointers << bs

      color = blend[:color] || {}
      setup_blend_component(bs[:color], color, "color")

      alpha = blend[:alpha] || {}
      setup_blend_component(bs[:alpha], alpha, "alpha")

      bs.to_ptr
    end

    def setup_blend_component(component, config, name)
      DescriptorHelpers.validate_keys!(
        config,
        allowed: %i[operation src_factor dst_factor],
        context: "#{name} blend component"
      )
      component[:operation] = Native::EnumHelper.coerce(
        Native::BlendOperation,
        config[:operation] || :add,
        name: "#{name} blend operation"
      )
      component[:src_factor] = Native::EnumHelper.coerce(
        Native::BlendFactor,
        config[:src_factor] || :one,
        name: "#{name} source blend factor"
      )
      component[:dst_factor] = Native::EnumHelper.coerce(
        Native::BlendFactor,
        config[:dst_factor] || :zero,
        name: "#{name} destination blend factor"
      )
    end

    def normalize_write_mask(mask)
      Native::EnumHelper.coerce_flags(
        Native::ColorWriteMask,
        mask || :all,
        name: "color write mask"
      )
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
