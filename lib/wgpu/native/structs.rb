# frozen_string_literal: true

module WGPU
  module Native
    class ChainedStruct < FFI::Struct
      layout :next, :pointer,
             :s_type, SType
    end

    class StringView < FFI::Struct
      layout :data, :pointer,
             :length, :size_t
    end

    class ChainedStructOut < FFI::Struct
      layout :next, :pointer,
             :s_type, SType
    end

    class Future < FFI::Struct
      layout :id, :uint64
    end

    class FutureWaitInfo < FFI::Struct
      layout :future, Future.by_value,
             :completed, :uint32
    end

    class InstanceCapabilities < FFI::Struct
      layout :next_in_chain, :pointer,
             :timed_wait_any_enable, :uint32,
             :timed_wait_any_max_count, :size_t
    end

    class InstanceDescriptor < FFI::Struct
      layout :next_in_chain, :pointer,
             :features, InstanceCapabilities
    end

    class RequestAdapterOptions < FFI::Struct
      layout :next_in_chain, :pointer,
             :feature_level, FeatureLevel,
             :power_preference, PowerPreference,
             :force_fallback_adapter, :uint32,
             :backend_type, BackendType,
             :compatible_surface, :pointer
    end

    class AdapterInfo < FFI::Struct
      layout :next_in_chain, :pointer,
             :vendor, StringView,
             :architecture, StringView,
             :device, StringView,
             :description, StringView,
             :backend_type, BackendType,
             :adapter_type, AdapterType,
             :vendor_id, :uint32,
             :device_id, :uint32
    end

    class QueueDescriptor < FFI::Struct
      layout :next_in_chain, :pointer,
             :label, StringView
    end

    class DeviceLostCallbackInfo < FFI::Struct
      layout :next_in_chain, :pointer,
             :mode, :uint32,
             :callback, :pointer,
             :userdata1, :pointer,
             :userdata2, :pointer
    end

    class UncapturedErrorCallbackInfo < FFI::Struct
      layout :next_in_chain, :pointer,
             :callback, :pointer,
             :userdata1, :pointer,
             :userdata2, :pointer
    end

    class PopErrorScopeCallbackInfo < FFI::Struct
      layout :next_in_chain, :pointer,
             :mode, :uint32,
             :callback, :pointer,
             :userdata1, :pointer,
             :userdata2, :pointer
    end

    class QueueWorkDoneCallbackInfo < FFI::Struct
      layout :next_in_chain, :pointer,
             :mode, :uint32,
             :callback, :pointer,
             :userdata1, :pointer,
             :userdata2, :pointer
    end

    class InstanceEnumerateAdapterOptions < FFI::Struct
      layout :next_in_chain, :pointer,
             :backends, :uint32
    end

    class Limits < FFI::Struct
      layout :max_texture_dimension_1d, :uint32,
             :max_texture_dimension_2d, :uint32,
             :max_texture_dimension_3d, :uint32,
             :max_texture_array_layers, :uint32,
             :max_bind_groups, :uint32,
             :max_bind_groups_plus_vertex_buffers, :uint32,
             :max_bindings_per_bind_group, :uint32,
             :max_dynamic_uniform_buffers_per_pipeline_layout, :uint32,
             :max_dynamic_storage_buffers_per_pipeline_layout, :uint32,
             :max_sampled_textures_per_shader_stage, :uint32,
             :max_samplers_per_shader_stage, :uint32,
             :max_storage_buffers_per_shader_stage, :uint32,
             :max_storage_textures_per_shader_stage, :uint32,
             :max_uniform_buffers_per_shader_stage, :uint32,
             :max_uniform_buffer_binding_size, :uint64,
             :max_storage_buffer_binding_size, :uint64,
             :min_uniform_buffer_offset_alignment, :uint32,
             :min_storage_buffer_offset_alignment, :uint32,
             :max_vertex_buffers, :uint32,
             :max_buffer_size, :uint64,
             :max_vertex_attributes, :uint32,
             :max_vertex_buffer_array_stride, :uint32,
             :max_inter_stage_shader_variables, :uint32,
             :max_color_attachments, :uint32,
             :max_color_attachment_bytes_per_sample, :uint32,
             :max_compute_workgroup_storage_size, :uint32,
             :max_compute_invocations_per_workgroup, :uint32,
             :max_compute_workgroup_size_x, :uint32,
             :max_compute_workgroup_size_y, :uint32,
             :max_compute_workgroup_size_z, :uint32,
             :max_compute_workgroups_per_dimension, :uint32,
             :max_subgroup_size, :uint32
    end

    class RequiredLimits < FFI::Struct
      layout :next_in_chain, :pointer,
             :limits, Limits
    end

    class DeviceDescriptor < FFI::Struct
      layout :next_in_chain, :pointer,
             :label, StringView,
             :required_feature_count, :size_t,
             :required_features, :pointer,
             :required_limits, :pointer,
             :default_queue, QueueDescriptor,
             :device_lost_callback_info, DeviceLostCallbackInfo,
             :uncaptured_error_callback_info, UncapturedErrorCallbackInfo
    end

    class BufferDescriptor < FFI::Struct
      layout :next_in_chain, :pointer,
             :label, StringView,
             :usage, :uint64,
             :size, :uint64,
             :mapped_at_creation, :uint32
    end

    class Extent3D < FFI::Struct
      layout :width, :uint32,
             :height, :uint32,
             :depth_or_array_layers, :uint32
    end

    class TextureDescriptor < FFI::Struct
      layout :next_in_chain, :pointer,
             :label, StringView,
             :usage, :uint64,
             :dimension, TextureDimension,
             :size, Extent3D,
             :format, TextureFormat,
             :mip_level_count, :uint32,
             :sample_count, :uint32,
             :view_format_count, :size_t,
             :view_formats, :pointer
    end

    class ShaderSourceSPIRV < FFI::Struct
      layout :chain, ChainedStruct,
             :code_size, :uint32,
             :code, :pointer
    end

    class ShaderSourceWGSL < FFI::Struct
      layout :chain, ChainedStruct,
             :code, StringView
    end

    class ShaderDefine < FFI::Struct
      layout :name, StringView,
             :value, StringView
    end

    class ShaderSourceGLSL < FFI::Struct
      layout :chain, ChainedStruct,
             :stage, :uint64,
             :code, StringView,
             :define_count, :uint32,
             :defines, :pointer
    end

    class ShaderModuleDescriptor < FFI::Struct
      layout :next_in_chain, :pointer,
             :label, StringView
    end

    class CommandEncoderDescriptor < FFI::Struct
      layout :next_in_chain, :pointer,
             :label, StringView
    end

    class CommandBufferDescriptor < FFI::Struct
      layout :next_in_chain, :pointer,
             :label, StringView
    end

    class Color < FFI::Struct
      layout :r, :double,
             :g, :double,
             :b, :double,
             :a, :double
    end

    class RenderPassColorAttachment < FFI::Struct
      layout :next_in_chain, :pointer,
             :view, :pointer,
             :depth_slice, :uint32,
             :resolve_target, :pointer,
             :load_op, LoadOp,
             :store_op, StoreOp,
             :clear_value, Color
    end

    class RenderPassDepthStencilAttachment < FFI::Struct
      layout :view, :pointer,
             :depth_load_op, LoadOp,
             :depth_store_op, StoreOp,
             :depth_clear_value, :float,
             :depth_read_only, :uint32,
             :stencil_load_op, LoadOp,
             :stencil_store_op, StoreOp,
             :stencil_clear_value, :uint32,
             :stencil_read_only, :uint32
    end

    class RenderPassTimestampWrites < FFI::Struct
      layout :query_set, :pointer,
             :beginning_of_pass_write_index, :uint32,
             :end_of_pass_write_index, :uint32
    end

    class RenderPassDescriptor < FFI::Struct
      layout :next_in_chain, :pointer,
             :label, StringView,
             :color_attachment_count, :size_t,
             :color_attachments, :pointer,
             :depth_stencil_attachment, :pointer,
             :occlusion_query_set, :pointer,
             :timestamp_writes, :pointer
    end

    class ComputePassDescriptor < FFI::Struct
      layout :next_in_chain, :pointer,
             :label, StringView,
             :timestamp_writes, :pointer
    end

    class ComputePassTimestampWrites < FFI::Struct
      layout :query_set, :pointer,
             :beginning_of_pass_write_index, :uint32,
             :end_of_pass_write_index, :uint32
    end

    class ConstantEntry < FFI::Struct
      layout :next_in_chain, :pointer,
             :key, StringView,
             :value, :double
    end

    class ProgrammableStageDescriptor < FFI::Struct
      layout :next_in_chain, :pointer,
             :module, :pointer,
             :entry_point, StringView,
             :constant_count, :size_t,
             :constants, :pointer
    end

    class ComputePipelineDescriptor < FFI::Struct
      layout :next_in_chain, :pointer,
             :label, StringView,
             :layout, :pointer,
             :compute, ProgrammableStageDescriptor
    end

    class BufferBindingLayout < FFI::Struct
      layout :next_in_chain, :pointer,
             :type, BufferBindingType,
             :has_dynamic_offset, :uint32,
             :min_binding_size, :uint64
    end

    class SamplerBindingLayout < FFI::Struct
      layout :next_in_chain, :pointer,
             :type, SamplerBindingType
    end

    class TextureBindingLayout < FFI::Struct
      layout :next_in_chain, :pointer,
             :sample_type, TextureSampleType,
             :view_dimension, TextureViewDimension,
             :multisampled, :uint32
    end

    class StorageTextureBindingLayout < FFI::Struct
      layout :next_in_chain, :pointer,
             :access, StorageTextureAccess,
             :format, TextureFormat,
             :view_dimension, TextureViewDimension
    end

    class BindGroupLayoutEntry < FFI::Struct
      layout :next_in_chain, :pointer,
             :binding, :uint32,
             :visibility, :uint64,
             :buffer, BufferBindingLayout,
             :sampler, SamplerBindingLayout,
             :texture, TextureBindingLayout,
             :storage_texture, StorageTextureBindingLayout
    end

    class BindGroupLayoutDescriptor < FFI::Struct
      layout :next_in_chain, :pointer,
             :label, StringView,
             :entry_count, :size_t,
             :entries, :pointer
    end

    class BindGroupEntry < FFI::Struct
      layout :next_in_chain, :pointer,
             :binding, :uint32,
             :buffer, :pointer,
             :offset, :uint64,
             :size, :uint64,
             :sampler, :pointer,
             :texture_view, :pointer
    end

    class BindGroupDescriptor < FFI::Struct
      layout :next_in_chain, :pointer,
             :label, StringView,
             :layout, :pointer,
             :entry_count, :size_t,
             :entries, :pointer
    end

    class PipelineLayoutDescriptor < FFI::Struct
      layout :next_in_chain, :pointer,
             :label, StringView,
             :bind_group_layout_count, :size_t,
             :bind_group_layouts, :pointer
    end

    class RequestAdapterCallbackInfo < FFI::Struct
      layout :next_in_chain, :pointer,
             :mode, :uint32,
             :callback, :pointer,
             :userdata1, :pointer,
             :userdata2, :pointer
    end

    class RequestDeviceCallbackInfo < FFI::Struct
      layout :next_in_chain, :pointer,
             :mode, :uint32,
             :callback, :pointer,
             :userdata1, :pointer,
             :userdata2, :pointer
    end

    class BufferMapCallbackInfo < FFI::Struct
      layout :next_in_chain, :pointer,
             :mode, :uint32,
             :callback, :pointer,
             :userdata1, :pointer,
             :userdata2, :pointer
    end

    class TextureViewDescriptor < FFI::Struct
      layout :next_in_chain, :pointer,
             :label, StringView,
             :format, TextureFormat,
             :dimension, TextureViewDimension,
             :base_mip_level, :uint32,
             :mip_level_count, :uint32,
             :base_array_layer, :uint32,
             :array_layer_count, :uint32,
             :aspect, TextureAspect
    end

    class SamplerDescriptor < FFI::Struct
      layout :next_in_chain, :pointer,
             :label, StringView,
             :address_mode_u, AddressMode,
             :address_mode_v, AddressMode,
             :address_mode_w, AddressMode,
             :mag_filter, FilterMode,
             :min_filter, FilterMode,
             :mipmap_filter, MipmapFilterMode,
             :lod_min_clamp, :float,
             :lod_max_clamp, :float,
             :compare, CompareFunction,
             :max_anisotropy, :uint16
    end

    class BlendComponent < FFI::Struct
      layout :operation, BlendOperation,
             :src_factor, BlendFactor,
             :dst_factor, BlendFactor
    end

    class BlendState < FFI::Struct
      layout :color, BlendComponent,
             :alpha, BlendComponent
    end

    class ColorTargetState < FFI::Struct
      layout :next_in_chain, :pointer,
             :format, TextureFormat,
             :blend, :pointer,
             :write_mask, :uint64
    end

    class FragmentState < FFI::Struct
      layout :next_in_chain, :pointer,
             :module, :pointer,
             :entry_point, StringView,
             :constant_count, :size_t,
             :constants, :pointer,
             :target_count, :size_t,
             :targets, :pointer
    end

    class VertexAttribute < FFI::Struct
      layout :format, VertexFormat,
             :offset, :uint64,
             :shader_location, :uint32
    end

    class VertexBufferLayout < FFI::Struct
      layout :step_mode, VertexStepMode,
             :array_stride, :uint64,
             :attribute_count, :size_t,
             :attributes, :pointer
    end

    class VertexState < FFI::Struct
      layout :next_in_chain, :pointer,
             :module, :pointer,
             :entry_point, StringView,
             :constant_count, :size_t,
             :constants, :pointer,
             :buffer_count, :size_t,
             :buffers, :pointer
    end

    class PrimitiveState < FFI::Struct
      layout :next_in_chain, :pointer,
             :topology, PrimitiveTopology,
             :strip_index_format, IndexFormat,
             :front_face, FrontFace,
             :cull_mode, CullMode,
             :unclipped_depth, :uint32
    end

    class StencilFaceState < FFI::Struct
      layout :compare, CompareFunction,
             :fail_op, StencilOperation,
             :depth_fail_op, StencilOperation,
             :pass_op, StencilOperation
    end

    class DepthStencilState < FFI::Struct
      layout :next_in_chain, :pointer,
             :format, TextureFormat,
             :depth_write_enabled, :uint32,
             :depth_compare, CompareFunction,
             :stencil_front, StencilFaceState,
             :stencil_back, StencilFaceState,
             :stencil_read_mask, :uint32,
             :stencil_write_mask, :uint32,
             :depth_bias, :int32,
             :depth_bias_slope_scale, :float,
             :depth_bias_clamp, :float
    end

    class MultisampleState < FFI::Struct
      layout :next_in_chain, :pointer,
             :count, :uint32,
             :mask, :uint32,
             :alpha_to_coverage_enabled, :uint32
    end

    class RenderPipelineDescriptor < FFI::Struct
      layout :next_in_chain, :pointer,
             :label, StringView,
             :layout, :pointer,
             :vertex, VertexState,
             :primitive, PrimitiveState,
             :depth_stencil, :pointer,
             :multisample, MultisampleState,
             :fragment, :pointer
    end

    class Origin3D < FFI::Struct
      layout :x, :uint32,
             :y, :uint32,
             :z, :uint32
    end

    class ImageCopyTexture < FFI::Struct
      layout :texture, :pointer,
             :mip_level, :uint32,
             :origin, Origin3D,
             :aspect, TextureAspect
    end

    class TextureDataLayout < FFI::Struct
      layout :offset, :uint64,
             :bytes_per_row, :uint32,
             :rows_per_image, :uint32
    end

    class SurfaceDescriptor < FFI::Struct
      layout :next_in_chain, :pointer,
             :label, StringView
    end

    class SurfaceCapabilities < FFI::Struct
      layout :next_in_chain, :pointer,
             :usages, :uint64,
             :format_count, :size_t,
             :formats, :pointer,
             :present_mode_count, :size_t,
             :present_modes, :pointer,
             :alpha_mode_count, :size_t,
             :alpha_modes, :pointer
    end

    class SurfaceConfiguration < FFI::Struct
      layout :next_in_chain, :pointer,
             :device, :pointer,
             :format, TextureFormat,
             :usage, :uint64,
             :width, :uint32,
             :height, :uint32,
             :view_format_count, :size_t,
             :view_formats, :pointer,
             :alpha_mode, :uint32,
             :present_mode, :uint32
    end

    class SurfaceTexture < FFI::Struct
      layout :next_in_chain, :pointer,
             :texture, :pointer,
             :status, :uint32
    end

    class SurfaceSourceMetalLayer < FFI::Struct
      layout :chain, ChainedStruct,
             :layer, :pointer
    end

    class SurfaceSourceWindowsHWND < FFI::Struct
      layout :chain, ChainedStruct,
             :hinstance, :pointer,
             :hwnd, :pointer
    end

    class SurfaceSourceXlibWindow < FFI::Struct
      layout :chain, ChainedStruct,
             :display, :pointer,
             :window, :uint64
    end

    class SurfaceSourceWaylandSurface < FFI::Struct
      layout :chain, ChainedStruct,
             :display, :pointer,
             :surface, :pointer
    end

    class SurfaceSourceXCBWindow < FFI::Struct
      layout :chain, ChainedStruct,
             :connection, :pointer,
             :window, :uint32
    end

    class QuerySetDescriptor < FFI::Struct
      layout :next_in_chain, :pointer,
             :label, StringView,
             :type, QueryType,
             :count, :uint32
    end

    class ImageCopyBuffer < FFI::Struct
      layout :layout, TextureDataLayout,
             :buffer, :pointer
    end

    class SupportedFeatures < FFI::Struct
      layout :feature_count, :size_t,
             :features, :pointer
    end

    class SupportedLimits < FFI::Struct
      layout :next_in_chain, :pointer,
             :limits, Limits
    end

    class CompilationMessage < FFI::Struct
      layout :next_in_chain, :pointer,
             :message, StringView,
             :type, CompilationMessageType,
             :line_num, :uint64,
             :line_pos, :uint64,
             :offset, :uint64,
             :length, :uint64
    end

    class CompilationInfo < FFI::Struct
      layout :next_in_chain, :pointer,
             :message_count, :size_t,
             :messages, :pointer
    end

    class CompilationInfoCallbackInfo < FFI::Struct
      layout :next_in_chain, :pointer,
             :mode, :uint32,
             :callback, :pointer,
             :userdata1, :pointer,
             :userdata2, :pointer
    end

    class RenderBundleDescriptor < FFI::Struct
      layout :next_in_chain, :pointer,
             :label, StringView
    end

    class RenderBundleEncoderDescriptor < FFI::Struct
      layout :next_in_chain, :pointer,
             :label, StringView,
             :color_format_count, :size_t,
             :color_formats, :pointer,
             :depth_stencil_format, TextureFormat,
             :sample_count, :uint32,
             :depth_read_only, :uint32,
             :stencil_read_only, :uint32
    end
  end
end
