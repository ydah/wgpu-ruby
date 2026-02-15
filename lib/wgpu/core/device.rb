# frozen_string_literal: true

module WGPU
  class Device
    attr_reader :handle, :queue, :adapter

    CALLBACK_MODE_WAIT_ANY_ONLY = 1
    LIMIT_FIELDS = Native::Limits.members.freeze

    def self.request(adapter, label: nil, required_features: [], required_limits: nil)
      device_ptr = FFI::MemoryPointer.new(:pointer)
      status_holder = { value: nil, message: nil }

      callback = FFI::Function.new(
        :void, [:uint32, :pointer, Native::StringView.by_value, :pointer]
      ) do |status, device, message, _userdata|
        status_holder[:value] = Native::RequestDeviceStatus[status]
        if message[:data] && !message[:data].null? && message[:length] > 0
          status_holder[:message] = message[:data].read_string(message[:length])
        end
        device_ptr.write_pointer(device)
      end

      queue_desc = Native::QueueDescriptor.new
      queue_desc[:next_in_chain] = nil
      queue_desc[:label][:data] = nil
      queue_desc[:label][:length] = 0

      device_lost_info = Native::DeviceLostCallbackInfo.new
      device_lost_info[:next_in_chain] = nil
      device_lost_info[:mode] = 0
      device_lost_info[:callback] = nil
      device_lost_info[:userdata] = nil

      error_info = Native::UncapturedErrorCallbackInfo.new
      error_info[:next_in_chain] = nil
      error_info[:callback] = nil
      error_info[:userdata] = nil

      desc = Native::DeviceDescriptor.new
      desc[:next_in_chain] = nil
      if label
        label_ptr = FFI::MemoryPointer.from_string(label)
        desc[:label][:data] = label_ptr
        desc[:label][:length] = label.bytesize
      else
        desc[:label][:data] = nil
        desc[:label][:length] = 0
      end

      feature_values = normalize_required_features(required_features)
      if feature_values.empty?
        desc[:required_feature_count] = 0
        desc[:required_features] = nil
      else
        features_ptr = FFI::MemoryPointer.new(:uint32, feature_values.size)
        features_ptr.write_array_of_uint32(feature_values)
        desc[:required_feature_count] = feature_values.size
        desc[:required_features] = features_ptr
      end

      required_limits_struct = build_required_limits(adapter, required_limits)
      desc[:required_limits] = required_limits_struct ? required_limits_struct.to_ptr : nil
      desc[:default_queue] = queue_desc
      desc[:device_lost_callback_info] = device_lost_info
      desc[:uncaptured_error_callback_info] = error_info

      callback_info = Native::RequestDeviceCallbackInfo.new
      callback_info[:next_in_chain] = nil
      callback_info[:mode] = CALLBACK_MODE_WAIT_ANY_ONLY
      callback_info[:callback] = callback
      callback_info[:userdata] = nil

      Native.wgpuAdapterRequestDevice(adapter.handle, desc, callback_info)

      handle = device_ptr.read_pointer
      if handle.null? || status_holder[:value] != :success
        msg = status_holder[:message] || "Unknown error"
        raise DeviceError, "Failed to request device: #{msg}"
      end

      new(handle, adapter: adapter)
    end

    def initialize(handle, adapter: nil)
      @handle = handle
      @adapter = adapter
      @queue = Queue.new(Native.wgpuDeviceGetQueue(@handle), device: self)
    end

    def adapter_info
      @adapter&.info
    end

    def create_buffer(label: nil, size:, usage:, mapped_at_creation: false)
      Buffer.new(self, label: label, size: size, usage: usage, mapped_at_creation: mapped_at_creation)
    end

    def create_shader_module(label: nil, code:, compilation_hints: [])
      ShaderModule.new(self, label: label, code: code, compilation_hints: compilation_hints)
    end

    def create_command_encoder(label: nil)
      CommandEncoder.new(self, label: label)
    end

    def create_bind_group_layout(label: nil, entries:)
      BindGroupLayout.new(self, label: label, entries: entries)
    end

    def create_bind_group(label: nil, layout:, entries:)
      BindGroup.new(self, label: label, layout: layout, entries: entries)
    end

    def create_pipeline_layout(label: nil, bind_group_layouts:)
      PipelineLayout.new(self, label: label, bind_group_layouts: bind_group_layouts)
    end

    def create_compute_pipeline(label: nil, layout:, compute:)
      ComputePipeline.new(self, label: label, layout: layout, compute: compute)
    end

    def create_compute_pipeline_async(label: nil, layout:, compute:)
      AsyncTask.new do
        create_compute_pipeline(label: label, layout: layout, compute: compute)
      end
    end

    def create_render_pipeline(label: nil, layout:, vertex:, primitive: {}, depth_stencil: nil, multisample: {}, fragment: nil)
      RenderPipeline.new(self,
        label: label,
        layout: layout,
        vertex: vertex,
        primitive: primitive,
        depth_stencil: depth_stencil,
        multisample: multisample,
        fragment: fragment
      )
    end

    def create_render_pipeline_async(label: nil, layout:, vertex:, primitive: {}, depth_stencil: nil, multisample: {}, fragment: nil)
      AsyncTask.new do
        create_render_pipeline(
          label: label,
          layout: layout,
          vertex: vertex,
          primitive: primitive,
          depth_stencil: depth_stencil,
          multisample: multisample,
          fragment: fragment
        )
      end
    end

    def create_texture(label: nil, size:, format:, usage:, dimension: :d2, mip_level_count: 1, sample_count: 1, view_formats: [])
      Texture.new(self,
        label: label,
        size: size,
        format: format,
        usage: usage,
        dimension: dimension,
        mip_level_count: mip_level_count,
        sample_count: sample_count,
        view_formats: view_formats
      )
    end

    def create_sampler(label: nil, address_mode_u: :clamp_to_edge, address_mode_v: :clamp_to_edge, address_mode_w: :clamp_to_edge, mag_filter: :nearest, min_filter: :nearest, mipmap_filter: :nearest, lod_min_clamp: 0.0, lod_max_clamp: 32.0, compare: nil, max_anisotropy: 1)
      Sampler.new(self,
        label: label,
        address_mode_u: address_mode_u,
        address_mode_v: address_mode_v,
        address_mode_w: address_mode_w,
        mag_filter: mag_filter,
        min_filter: min_filter,
        mipmap_filter: mipmap_filter,
        lod_min_clamp: lod_min_clamp,
        lod_max_clamp: lod_max_clamp,
        compare: compare,
        max_anisotropy: max_anisotropy
      )
    end

    def create_buffer_with_data(label: nil, data:, usage:)
      data_ptr, byte_size = data_to_pointer(data)
      buffer = create_buffer(
        label: label,
        size: byte_size,
        usage: usage,
        mapped_at_creation: true
      )
      buffer.mapped_range.write_bytes(data_ptr.read_bytes(byte_size))
      buffer.unmap
      buffer
    end

    def create_query_set(label: nil, type:, count:)
      QuerySet.new(self, label: label, type: type, count: count)
    end

    def create_render_bundle_encoder(color_formats:, depth_stencil_format: nil, sample_count: 1,
                                     depth_read_only: false, stencil_read_only: false, label: nil)
      RenderBundleEncoder.new(self,
        color_formats: color_formats,
        depth_stencil_format: depth_stencil_format,
        sample_count: sample_count,
        depth_read_only: depth_read_only,
        stencil_read_only: stencil_read_only,
        label: label
      )
    end

    def features
      supported = Native::SupportedFeatures.new
      Native.wgpuDeviceGetFeatures(@handle, supported)

      result = []
      if supported[:feature_count] > 0 && !supported[:features].null?
        supported[:features].read_array_of_uint32(supported[:feature_count]).each do |f|
          result << Native::FeatureName[f]
        end
      end
      result
    end

    def has_feature?(feature)
      features.include?(feature)
    end

    def limits
      supported = Native::SupportedLimits.new
      supported[:next_in_chain] = nil
      Native.wgpuDeviceGetLimits(@handle, supported)
      limits_to_hash(supported[:limits])
    end

    def poll(wait: false)
      Native.wgpuDevicePoll(@handle, wait ? 1 : 0, nil)
    end

    def push_error_scope(filter = :validation)
      Native.wgpuDevicePushErrorScope(@handle, filter)
    end

    def pop_error_scope
      error_holder = { type: nil, message: nil }

      callback = FFI::Function.new(
        :void, [:uint32, :uint32, Native::StringView.by_value, :pointer, :pointer]
      ) do |_status, error_type, message, _userdata1, _userdata2|
        error_holder[:type] = Native::ErrorType[error_type]
        if message[:data] && !message[:data].null? && message[:length] > 0
          error_holder[:message] = message[:data].read_string(message[:length])
        end
      end

      callback_info = Native::PopErrorScopeCallbackInfo.new
      callback_info[:next_in_chain] = nil
      callback_info[:mode] = 1
      callback_info[:callback] = callback
      callback_info[:userdata1] = nil
      callback_info[:userdata2] = nil

      Native.wgpuDevicePopErrorScope(@handle, callback_info)

      error_holder
    end

    def pop_error_scope_async
      AsyncTask.new { pop_error_scope }
    end

    def with_error_scope(filter = :validation)
      push_error_scope(filter)
      result = yield
      error = pop_error_scope
      if error[:type] && error[:type] != :no_error
        raise Error, "GPU error (#{error[:type]}): #{error[:message]}"
      end
      result
    end

    def destroy
      return if @handle.null?
      Native.wgpuDeviceDestroy(@handle)
    end

    def release
      @queue&.release
      return if @handle.null?
      Native.wgpuDeviceRelease(@handle)
      @handle = FFI::Pointer::NULL
    end

    private

    def self.normalize_required_features(required_features)
      Array(required_features).map do |feature|
        normalize_feature_name(feature)
      end
    end

    def self.normalize_feature_name(feature)
      return feature if feature.is_a?(Integer)

      key = feature.to_s.strip.tr("-", "_").to_sym
      value = Native::FeatureName[key]
      raise ArgumentError, "Unknown feature name: #{feature}" if value.nil?

      value
    end

    def self.build_required_limits(adapter, required_limits)
      return nil if required_limits.nil?
      raise ArgumentError, "required_limits must be a Hash" unless required_limits.is_a?(Hash)

      resolved_limits = adapter.limits.dup
      required_limits.each do |name, value|
        key = canonical_limit_key(name)
        resolved_limits[key] = value unless value.nil?
      end

      required = Native::RequiredLimits.new
      required[:next_in_chain] = nil
      LIMIT_FIELDS.each do |field|
        required[:limits][field] = resolved_limits[field] || 0
      end
      required
    end

    def self.canonical_limit_key(name)
      normalized = name.to_s
                       .gsub(/([A-Z])/, "_\\1")
                       .downcase
                       .tr("-", "_")
                       .sub(/^_/, "")
                       .to_sym
      return normalized if LIMIT_FIELDS.include?(normalized)

      raise ArgumentError, "Unknown limit key: #{name}"
    end

    def data_to_pointer(data)
      case data
      when String
        ptr = FFI::MemoryPointer.new(:char, data.bytesize)
        ptr.put_bytes(0, data)
        [ptr, data.bytesize]
      when Array
        ptr = FFI::MemoryPointer.new(:float, data.size)
        ptr.write_array_of_float(data)
        [ptr, data.size * 4]
      when FFI::Pointer
        [data, data.size]
      else
        raise ArgumentError, "Unsupported data type: #{data.class}"
      end
    end

    def limits_to_hash(limits)
      {
        max_texture_dimension_1d: limits[:max_texture_dimension_1d],
        max_texture_dimension_2d: limits[:max_texture_dimension_2d],
        max_texture_dimension_3d: limits[:max_texture_dimension_3d],
        max_texture_array_layers: limits[:max_texture_array_layers],
        max_bind_groups: limits[:max_bind_groups],
        max_bind_groups_plus_vertex_buffers: limits[:max_bind_groups_plus_vertex_buffers],
        max_bindings_per_bind_group: limits[:max_bindings_per_bind_group],
        max_dynamic_uniform_buffers_per_pipeline_layout: limits[:max_dynamic_uniform_buffers_per_pipeline_layout],
        max_dynamic_storage_buffers_per_pipeline_layout: limits[:max_dynamic_storage_buffers_per_pipeline_layout],
        max_sampled_textures_per_shader_stage: limits[:max_sampled_textures_per_shader_stage],
        max_samplers_per_shader_stage: limits[:max_samplers_per_shader_stage],
        max_storage_buffers_per_shader_stage: limits[:max_storage_buffers_per_shader_stage],
        max_storage_textures_per_shader_stage: limits[:max_storage_textures_per_shader_stage],
        max_uniform_buffers_per_shader_stage: limits[:max_uniform_buffers_per_shader_stage],
        max_uniform_buffer_binding_size: limits[:max_uniform_buffer_binding_size],
        max_storage_buffer_binding_size: limits[:max_storage_buffer_binding_size],
        min_uniform_buffer_offset_alignment: limits[:min_uniform_buffer_offset_alignment],
        min_storage_buffer_offset_alignment: limits[:min_storage_buffer_offset_alignment],
        max_vertex_buffers: limits[:max_vertex_buffers],
        max_buffer_size: limits[:max_buffer_size],
        max_vertex_attributes: limits[:max_vertex_attributes],
        max_vertex_buffer_array_stride: limits[:max_vertex_buffer_array_stride],
        max_inter_stage_shader_variables: limits[:max_inter_stage_shader_variables],
        max_color_attachments: limits[:max_color_attachments],
        max_color_attachment_bytes_per_sample: limits[:max_color_attachment_bytes_per_sample],
        max_compute_workgroup_storage_size: limits[:max_compute_workgroup_storage_size],
        max_compute_invocations_per_workgroup: limits[:max_compute_invocations_per_workgroup],
        max_compute_workgroup_size_x: limits[:max_compute_workgroup_size_x],
        max_compute_workgroup_size_y: limits[:max_compute_workgroup_size_y],
        max_compute_workgroup_size_z: limits[:max_compute_workgroup_size_z],
        max_compute_workgroups_per_dimension: limits[:max_compute_workgroups_per_dimension],
        max_subgroup_size: limits[:max_subgroup_size]
      }
    end
  end
end
