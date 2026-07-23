# frozen_string_literal: true

module WGPU
  class Adapter
    attr_reader :handle, :instance

    # Wraps an existing native adapter handle.
    # @param handle [FFI::Pointer] native adapter handle
    # @param instance [Instance, nil] instance that owns the adapter
    # @return [Adapter]
    def self.from_handle(handle, instance: nil)
      adapter = adopt_native_handle(handle)
      adapter.instance_variable_set(:@instance, instance)
      adapter
    end

    # Requests an adapter and waits for the native callback.
    #
    # @param instance [Instance] instance used for discovery and callback progress
    # @param power_preference [Symbol, Integer] preferred power profile
    # @param backend [Symbol, Integer, nil] backend to restrict discovery to
    # @param feature_level [Symbol, Integer] requested WebGPU feature level
    # @param force_fallback_adapter [Boolean] whether to require a fallback adapter
    # @param compatible_surface [Surface, nil] surface the adapter must support
    # @param timeout [Numeric, nil] maximum wait time in seconds
    # @return [Adapter] requested adapter
    # @raise [AdapterError] if no adapter can be acquired
    # @raise [TimeoutError] if the request exceeds +timeout+
    def self.request(instance, power_preference: :high_performance, backend: nil, feature_level: :core,
                     force_fallback_adapter: false, compatible_surface: nil, timeout: nil)
      adapter_ptr = FFI::MemoryPointer.new(:pointer)
      status_holder = {
        done: false,
        value: nil,
        message: nil,
        abandoned: false,
        cleanup_claimed: false,
        mutex: Mutex.new
      }

      callback_token = nil
      callback = FFI::Function.new(
        :void, [:uint32, :pointer, Native::StringView.by_value, :pointer, :pointer]
      ) do |status, adapter, message, _userdata1, _userdata2|
        abandoned_adapter = nil
        begin
          status_holder[:mutex].synchronize do
            status_holder[:value] = Native::RequestAdapterStatus[status]
            if message[:data] && !message[:data].null? && message[:length] > 0
              status_holder[:message] = message[:data].read_string(message[:length])
            end
            adapter_ptr.write_pointer(adapter)
            status_holder[:done] = true
            if status_holder[:abandoned] && !status_holder[:cleanup_claimed]
              status_holder[:cleanup_claimed] = true
              abandoned_adapter = adapter
            end
          end
          Native.wgpuAdapterRelease(abandoned_adapter) if abandoned_adapter && !abandoned_adapter.null?
        ensure
          CallbackKeepalive.release(instance, callback_token)
        end
      end

      options = Native::RequestAdapterOptions.new
      options[:next_in_chain] = nil
      options[:feature_level] = Native::EnumHelper.coerce(
        Native::FeatureLevel,
        feature_level,
        name: "feature level"
      )
      options[:power_preference] = Native::EnumHelper.coerce(
        Native::PowerPreference,
        power_preference,
        name: "power preference"
      )
      options[:force_fallback_adapter] = force_fallback_adapter ? 1 : 0
      options[:backend_type] = Native::EnumHelper.coerce(
        Native::BackendType,
        backend || :undefined,
        name: "backend type"
      )
      options[:compatible_surface] = compatible_surface&.handle

      callback_info = Native::RequestAdapterCallbackInfo.new
      callback_info[:next_in_chain] = nil
      callback_info[:mode] = AsyncWaiter.callback_mode(instance: instance)
      callback_info[:callback] = callback
      callback_info[:userdata1] = nil
      callback_info[:userdata2] = nil

      callback_token = CallbackKeepalive.retain(instance, callback)
      future =
        begin
          Native.wgpuInstanceRequestAdapter(instance.handle, options, callback_info)
        rescue StandardError
          CallbackKeepalive.release(instance, callback_token)
          raise
        end

      begin
        AsyncWaiter.wait(status_holder: status_holder, instance: instance, future: future, timeout: timeout)
      rescue TimeoutError
        abandoned_adapter = status_holder[:mutex].synchronize do
          status_holder[:abandoned] = true
          next unless status_holder[:done] && !status_holder[:cleanup_claimed]

          status_holder[:cleanup_claimed] = true
          adapter_ptr.read_pointer
        end
        Native.wgpuAdapterRelease(abandoned_adapter) if abandoned_adapter && !abandoned_adapter.null?
        raise
      end

      handle = adapter_ptr.read_pointer
      if handle.null? || status_holder[:value] != :success
        msg = status_holder[:message] || "Unknown error"
        raise AdapterError, "Failed to request adapter: #{msg}"
      end

      new(handle, instance: instance)
    end

    # Wraps a native adapter handle.
    # @param handle [FFI::Pointer] native adapter handle
    # @param instance [Instance, nil] instance that owns the adapter
    def initialize(handle, instance: nil)
      @handle = handle
      @instance = instance
    end

    # Requests a logical device from this adapter.
    # @return [Device]
    def request_device(label: nil, required_features: [], required_limits: nil, timeout: nil)
      Device.request(
        self,
        label: label,
        required_features: required_features,
        required_limits: required_limits,
        timeout: timeout
      )
    end

    # Requests a logical device on a background task.
    # @return [AsyncTask] task yielding a {Device}
    def request_device_async(label: nil, required_features: [], required_limits: nil, timeout: nil)
      AsyncTask.new do
        request_device(
          label: label,
          required_features: required_features,
          required_limits: required_limits,
          timeout: timeout
        )
      end
    end

    # Returns identifying and backend information for the adapter.
    # @return [Hash]
    def info
      info_struct = Native::AdapterInfo.new
      Native.wgpuAdapterGetInfo(@handle, info_struct)

      result = {
        vendor: string_view_to_string(info_struct[:vendor]),
        architecture: string_view_to_string(info_struct[:architecture]),
        device: string_view_to_string(info_struct[:device]),
        description: string_view_to_string(info_struct[:description]),
        backend_type: info_struct[:backend_type],
        adapter_type: info_struct[:adapter_type],
        vendor_id: info_struct[:vendor_id],
        device_id: info_struct[:device_id]
      }

      Native.wgpuAdapterInfoFreeMembers(info_struct)
      result
    end

    # Returns the adapter's device name.
    # @return [String]
    def name
      info[:device]
    end

    # Returns the adapter vendor name.
    # @return [String]
    def vendor
      info[:vendor]
    end

    # Returns the backend used by the adapter.
    # @return [Symbol, Integer]
    def backend_type
      info[:backend_type]
    end

    # Returns the adapter's device classification.
    # @return [Symbol, Integer]
    def adapter_type
      info[:adapter_type]
    end

    # Lists optional features supported by the adapter.
    # @return [Array<Symbol>]
    def features
      supported = Native::SupportedFeatures.new
      Native.wgpuAdapterGetFeatures(@handle, supported)

      result = []
      if supported[:feature_count] > 0 && !supported[:features].null?
        supported[:features].read_array_of_uint32(supported[:feature_count]).each do |f|
          result << Native::FeatureName[f]
        end
      end
      result
    end

    # Reports whether the adapter supports a feature.
    # @param feature [Symbol] feature name
    # @return [Boolean]
    def has_feature?(feature)
      features.include?(feature)
    end

    # Returns the adapter resource limits.
    # @return [Hash{Symbol => Integer}]
    def limits
      supported = Native::SupportedLimits.new
      supported[:next_in_chain] = nil
      Native.wgpuAdapterGetLimits(@handle, supported)
      limits_to_hash(supported[:limits])
    end

    # Returns a concise human-readable adapter description.
    # @return [String]
    def summary
      info_hash = info
      "#{info_hash[:device]} (#{info_hash[:adapter_type]}) via #{info_hash[:backend_type]}"
    end

    # Releases the native adapter handle.
    #
    # Calling this method more than once has no effect.
    # @return [void]
    def release
      return if @handle.null?
      Native.wgpuAdapterRelease(@handle)
      @handle = FFI::Pointer::NULL
    end

    private

    def string_view_to_string(string_view)
      return "" if string_view[:data].null? || string_view[:length] == 0
      string_view[:data].read_string(string_view[:length])
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
