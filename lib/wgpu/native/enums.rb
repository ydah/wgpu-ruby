# frozen_string_literal: true

module WGPU
  module Native
    SType = enum(
      :invalid, 0x00000000,
      :shader_source_spirv, 0x00000001,
      :shader_source_wgsl, 0x00000002,
      :render_pass_max_draw_count, 0x00000003,
      :surface_source_metal_layer, 0x00000004,
      :surface_source_windows_hwnd, 0x00000005,
      :surface_source_xlib_window, 0x00000006,
      :surface_source_wayland_surface, 0x00000007,
      :surface_source_android_native_window, 0x00000008,
      :surface_source_xcb_window, 0x00000009,
      :shader_source_glsl, 0x00030004
    )

    BackendType = enum(
      :undefined, 0x00000000,
      :null, 0x00000001,
      :webgpu, 0x00000002,
      :d3d11, 0x00000003,
      :d3d12, 0x00000004,
      :metal, 0x00000005,
      :vulkan, 0x00000006,
      :opengl, 0x00000007,
      :opengles, 0x00000008
    )

    AdapterType = enum(
      :discrete_gpu, 0x00000001,
      :integrated_gpu, 0x00000002,
      :cpu, 0x00000003,
      :unknown, 0x00000004
    )

    PowerPreference = enum(
      :undefined, 0x00000000,
      :low_power, 0x00000001,
      :high_performance, 0x00000002
    )

    FeatureLevel = enum(
      :compatibility, 0x00000001,
      :core, 0x00000002
    )

    RequestAdapterStatus = enum(
      :success, 0x00000001,
      :instance_dropped, 0x00000002,
      :unavailable, 0x00000003,
      :error, 0x00000004,
      :unknown, 0x00000005
    )

    RequestDeviceStatus = enum(
      :success, 0x00000001,
      :instance_dropped, 0x00000002,
      :error, 0x00000003,
      :unknown, 0x00000004
    )

    BufferMapState = enum(
      :unmapped, 0x00000001,
      :pending, 0x00000002,
      :mapped, 0x00000003
    )

    CallbackMode = enum(
      :wait_any_only, 0x00000001,
      :allow_process_events, 0x00000002,
      :allow_spontaneous, 0x00000003
    )

    MapAsyncStatus = enum(
      :success, 0x00000001,
      :instance_dropped, 0x00000002,
      :error, 0x00000003,
      :aborted, 0x00000004,
      :unknown, 0x00000005
    )

    BufferUsage = {
      none: 0x0000000000000000,
      map_read: 0x0000000000000001,
      map_write: 0x0000000000000002,
      copy_src: 0x0000000000000004,
      copy_dst: 0x0000000000000008,
      index: 0x0000000000000010,
      vertex: 0x0000000000000020,
      uniform: 0x0000000000000040,
      storage: 0x0000000000000080,
      indirect: 0x0000000000000100,
      query_resolve: 0x0000000000000200
    }.freeze

    MapMode = {
      none: 0x0000000000000000,
      read: 0x0000000000000001,
      write: 0x0000000000000002
    }.freeze

    ShaderStage = {
      none: 0x0000000000000000,
      vertex: 0x0000000000000001,
      fragment: 0x0000000000000002,
      compute: 0x0000000000000004
    }.freeze

    TextureFormat = enum(
      :undefined, 0x00000000,
      :r8_unorm, 0x00000001,
      :r8_snorm, 0x00000002,
      :r8_uint, 0x00000003,
      :r8_sint, 0x00000004,
      :r16_uint, 0x00000005,
      :r16_sint, 0x00000006,
      :r16_float, 0x00000007,
      :rg8_unorm, 0x00000008,
      :rg8_snorm, 0x00000009,
      :rg8_uint, 0x0000000A,
      :rg8_sint, 0x0000000B,
      :r32_float, 0x0000000C,
      :r32_uint, 0x0000000D,
      :r32_sint, 0x0000000E,
      :rg16_uint, 0x0000000F,
      :rg16_sint, 0x00000010,
      :rg16_float, 0x00000011,
      :rgba8_unorm, 0x00000012,
      :rgba8_unorm_srgb, 0x00000013,
      :rgba8_snorm, 0x00000014,
      :rgba8_uint, 0x00000015,
      :rgba8_sint, 0x00000016,
      :bgra8_unorm, 0x00000017,
      :bgra8_unorm_srgb, 0x00000018,
      :rgb10a2_uint, 0x00000019,
      :rgb10a2_unorm, 0x0000001A,
      :rg11b10_ufloat, 0x0000001B,
      :rgb9e5_ufloat, 0x0000001C,
      :rg32_float, 0x0000001D,
      :rg32_uint, 0x0000001E,
      :rg32_sint, 0x0000001F,
      :rgba16_uint, 0x00000020,
      :rgba16_sint, 0x00000021,
      :rgba16_float, 0x00000022,
      :rgba32_float, 0x00000023,
      :rgba32_uint, 0x00000024,
      :rgba32_sint, 0x00000025,
      :stencil8, 0x00000026,
      :depth16_unorm, 0x00000027,
      :depth24_plus, 0x00000028,
      :depth24_plus_stencil8, 0x00000029,
      :depth32_float, 0x0000002A,
      :depth32_float_stencil8, 0x0000002B,
      :bc1_rgba_unorm, 0x0000002C,
      :bc1_rgba_unorm_srgb, 0x0000002D,
      :bc2_rgba_unorm, 0x0000002E,
      :bc2_rgba_unorm_srgb, 0x0000002F,
      :bc3_rgba_unorm, 0x00000030,
      :bc3_rgba_unorm_srgb, 0x00000031,
      :bc4_r_unorm, 0x00000032,
      :bc4_r_snorm, 0x00000033,
      :bc5_rg_unorm, 0x00000034,
      :bc5_rg_snorm, 0x00000035,
      :bc6h_rgb_ufloat, 0x00000036,
      :bc6h_rgb_float, 0x00000037,
      :bc7_rgba_unorm, 0x00000038,
      :bc7_rgba_unorm_srgb, 0x00000039,
      :etc2_rgb8_unorm, 0x0000003A,
      :etc2_rgb8_unorm_srgb, 0x0000003B,
      :etc2_rgb8a1_unorm, 0x0000003C,
      :etc2_rgb8a1_unorm_srgb, 0x0000003D,
      :etc2_rgba8_unorm, 0x0000003E,
      :etc2_rgba8_unorm_srgb, 0x0000003F,
      :eac_r11_unorm, 0x00000040,
      :eac_r11_snorm, 0x00000041,
      :eac_rg11_unorm, 0x00000042,
      :eac_rg11_snorm, 0x00000043,
      :astc_4x4_unorm, 0x00000044,
      :astc_4x4_unorm_srgb, 0x00000045,
      :astc_5x4_unorm, 0x00000046,
      :astc_5x4_unorm_srgb, 0x00000047,
      :astc_5x5_unorm, 0x00000048,
      :astc_5x5_unorm_srgb, 0x00000049,
      :astc_6x5_unorm, 0x0000004A,
      :astc_6x5_unorm_srgb, 0x0000004B,
      :astc_6x6_unorm, 0x0000004C,
      :astc_6x6_unorm_srgb, 0x0000004D,
      :astc_8x5_unorm, 0x0000004E,
      :astc_8x5_unorm_srgb, 0x0000004F,
      :astc_8x6_unorm, 0x00000050,
      :astc_8x6_unorm_srgb, 0x00000051,
      :astc_8x8_unorm, 0x00000052,
      :astc_8x8_unorm_srgb, 0x00000053,
      :astc_10x5_unorm, 0x00000054,
      :astc_10x5_unorm_srgb, 0x00000055,
      :astc_10x6_unorm, 0x00000056,
      :astc_10x6_unorm_srgb, 0x00000057,
      :astc_10x8_unorm, 0x00000058,
      :astc_10x8_unorm_srgb, 0x00000059,
      :astc_10x10_unorm, 0x0000005A,
      :astc_10x10_unorm_srgb, 0x0000005B,
      :astc_12x10_unorm, 0x0000005C,
      :astc_12x10_unorm_srgb, 0x0000005D,
      :astc_12x12_unorm, 0x0000005E,
      :astc_12x12_unorm_srgb, 0x0000005F
    )

    PrimitiveTopology = enum(
      :undefined, 0x00000000,
      :point_list, 0x00000001,
      :line_list, 0x00000002,
      :line_strip, 0x00000003,
      :triangle_list, 0x00000004,
      :triangle_strip, 0x00000005
    )

    LoadOp = enum(
      :undefined, 0x00000000,
      :load, 0x00000001,
      :clear, 0x00000002
    )

    StoreOp = enum(
      :undefined, 0x00000000,
      :store, 0x00000001,
      :discard, 0x00000002
    )

    TextureDimension = enum(
      :undefined, 0x00000000,
      :d1, 0x00000001,
      :d2, 0x00000002,
      :d3, 0x00000003
    )

    TextureUsage = {
      none: 0x0000000000000000,
      copy_src: 0x0000000000000001,
      copy_dst: 0x0000000000000002,
      texture_binding: 0x0000000000000004,
      storage_binding: 0x0000000000000008,
      render_attachment: 0x0000000000000010
    }.freeze

    VertexFormat = enum(
      :uint8, 0x00000001,
      :uint8x2, 0x00000002,
      :uint8x4, 0x00000003,
      :sint8, 0x00000004,
      :sint8x2, 0x00000005,
      :sint8x4, 0x00000006,
      :unorm8, 0x00000007,
      :unorm8x2, 0x00000008,
      :unorm8x4, 0x00000009,
      :snorm8, 0x0000000A,
      :snorm8x2, 0x0000000B,
      :snorm8x4, 0x0000000C,
      :uint16, 0x0000000D,
      :uint16x2, 0x0000000E,
      :uint16x4, 0x0000000F,
      :sint16, 0x00000010,
      :sint16x2, 0x00000011,
      :sint16x4, 0x00000012,
      :unorm16, 0x00000013,
      :unorm16x2, 0x00000014,
      :unorm16x4, 0x00000015,
      :snorm16, 0x00000016,
      :snorm16x2, 0x00000017,
      :snorm16x4, 0x00000018,
      :float16, 0x00000019,
      :float16x2, 0x0000001A,
      :float16x4, 0x0000001B,
      :float32, 0x0000001C,
      :float32x2, 0x0000001D,
      :float32x3, 0x0000001E,
      :float32x4, 0x0000001F,
      :uint32, 0x00000020,
      :uint32x2, 0x00000021,
      :uint32x3, 0x00000022,
      :uint32x4, 0x00000023,
      :sint32, 0x00000024,
      :sint32x2, 0x00000025,
      :sint32x3, 0x00000026,
      :sint32x4, 0x00000027
    )

    IndexFormat = enum(
      :undefined, 0x00000000,
      :uint16, 0x00000001,
      :uint32, 0x00000002
    )

    BufferBindingType = enum(
      :binding_not_used, 0x00000000,
      :undefined, 0x00000001,
      :uniform, 0x00000002,
      :storage, 0x00000003,
      :read_only_storage, 0x00000004
    )

    SamplerBindingType = enum(
      :binding_not_used, 0x00000000,
      :undefined, 0x00000001,
      :filtering, 0x00000002,
      :non_filtering, 0x00000003,
      :comparison, 0x00000004
    )

    TextureSampleType = enum(
      :binding_not_used, 0x00000000,
      :undefined, 0x00000001,
      :float, 0x00000002,
      :unfilterable_float, 0x00000003,
      :depth, 0x00000004,
      :sint, 0x00000005,
      :uint, 0x00000006
    )

    StorageTextureAccess = enum(
      :binding_not_used, 0x00000000,
      :undefined, 0x00000001,
      :write_only, 0x00000002,
      :read_only, 0x00000003,
      :read_write, 0x00000004
    )

    TextureViewDimension = enum(
      :undefined, 0x00000000,
      :d1, 0x00000001,
      :d2, 0x00000002,
      :d2_array, 0x00000003,
      :cube, 0x00000004,
      :cube_array, 0x00000005,
      :d3, 0x00000006
    )

    TextureAspect = enum(
      :undefined, 0x00000000,
      :all, 0x00000001,
      :stencil_only, 0x00000002,
      :depth_only, 0x00000003
    )

    AddressMode = enum(
      :undefined, 0x00000000,
      :clamp_to_edge, 0x00000001,
      :repeat, 0x00000002,
      :mirror_repeat, 0x00000003
    )

    FilterMode = enum(
      :undefined, 0x00000000,
      :nearest, 0x00000001,
      :linear, 0x00000002
    )

    MipmapFilterMode = enum(
      :undefined, 0x00000000,
      :nearest, 0x00000001,
      :linear, 0x00000002
    )

    CompareFunction = enum(
      :undefined, 0x00000000,
      :never, 0x00000001,
      :less, 0x00000002,
      :less_equal, 0x00000003,
      :greater, 0x00000004,
      :greater_equal, 0x00000005,
      :equal, 0x00000006,
      :not_equal, 0x00000007,
      :always, 0x00000008
    )

    FrontFace = enum(
      :undefined, 0x00000000,
      :ccw, 0x00000001,
      :cw, 0x00000002
    )

    CullMode = enum(
      :undefined, 0x00000000,
      :none, 0x00000001,
      :front, 0x00000002,
      :back, 0x00000003
    )

    BlendFactor = enum(
      :undefined, 0x00000000,
      :zero, 0x00000001,
      :one, 0x00000002,
      :src, 0x00000003,
      :one_minus_src, 0x00000004,
      :src_alpha, 0x00000005,
      :one_minus_src_alpha, 0x00000006,
      :dst, 0x00000007,
      :one_minus_dst, 0x00000008,
      :dst_alpha, 0x00000009,
      :one_minus_dst_alpha, 0x0000000A,
      :src_alpha_saturated, 0x0000000B,
      :constant, 0x0000000C,
      :one_minus_constant, 0x0000000D,
      :src1, 0x0000000E,
      :one_minus_src1, 0x0000000F,
      :src1_alpha, 0x00000010,
      :one_minus_src1_alpha, 0x00000011
    )

    BlendOperation = enum(
      :undefined, 0x00000000,
      :add, 0x00000001,
      :subtract, 0x00000002,
      :reverse_subtract, 0x00000003,
      :min, 0x00000004,
      :max, 0x00000005
    )

    ColorWriteMask = {
      none: 0x00000000,
      red: 0x00000001,
      green: 0x00000002,
      blue: 0x00000004,
      alpha: 0x00000008,
      all: 0x0000000F
    }.freeze

    VertexStepMode = enum(
      :vertex_buffer_not_used, 0x00000000,
      :undefined, 0x00000001,
      :vertex, 0x00000002,
      :instance, 0x00000003
    )

    StencilOperation = enum(
      :undefined, 0x00000000,
      :keep, 0x00000001,
      :zero, 0x00000002,
      :replace, 0x00000003,
      :invert, 0x00000004,
      :increment_clamp, 0x00000005,
      :decrement_clamp, 0x00000006,
      :increment_wrap, 0x00000007,
      :decrement_wrap, 0x00000008
    )

    PresentMode = enum(
      :undefined, 0x00000000,
      :fifo, 0x00000001,
      :fifo_relaxed, 0x00000002,
      :immediate, 0x00000003,
      :mailbox, 0x00000004
    )

    CompositeAlphaMode = enum(
      :auto, 0x00000000,
      :opaque, 0x00000001,
      :premultiplied, 0x00000002,
      :unpremultiplied, 0x00000003,
      :inherit, 0x00000004
    )

    SurfaceGetCurrentTextureStatus = enum(
      :success_optimal, 0x00000001,
      :success_suboptimal, 0x00000002,
      :timeout, 0x00000003,
      :outdated, 0x00000004,
      :lost, 0x00000005,
      :error, 0x00000006
    )

    QueryType = enum(
      :occlusion, 0x00000001,
      :timestamp, 0x00000002
    )

    ErrorFilter = enum(
      :validation, 0x00000001,
      :out_of_memory, 0x00000002,
      :internal, 0x00000003
    )

    ErrorType = enum(
      :no_error, 0x00000001,
      :validation, 0x00000002,
      :out_of_memory, 0x00000003,
      :internal, 0x00000004,
      :unknown, 0x00000005
    )

    PopErrorScopeStatus = enum(
      :success, 0x00000001,
      :instance_dropped, 0x00000002,
      :empty_stack, 0x00000003
    )

    WaitStatus = enum(
      :success, 0x00000001,
      :timed_out, 0x00000002,
      :unsupported_timeout, 0x00000003,
      :unsupported_count, 0x00000004,
      :unsupported_mixed_sources, 0x00000005
    )

    QueueWorkDoneStatus = enum(
      :success, 0x00000001,
      :instance_dropped, 0x00000002,
      :error, 0x00000003,
      :unknown, 0x00000004
    )

    CompilationInfoRequestStatus = enum(
      :success, 0x00000001,
      :instance_dropped, 0x00000002,
      :error, 0x00000003,
      :unknown, 0x00000004
    )

    CompilationMessageType = enum(
      :error, 0x00000001,
      :warning, 0x00000002,
      :info, 0x00000003
    )

    FeatureName = enum(
      :undefined, 0x00000000,
      :depth_clip_control, 0x00000001,
      :depth32_float_stencil8, 0x00000002,
      :timestamp_query, 0x00000003,
      :texture_compression_bc, 0x00000004,
      :texture_compression_bc_sliced_3d, 0x00000005,
      :texture_compression_etc2, 0x00000006,
      :texture_compression_astc, 0x00000007,
      :texture_compression_astc_sliced_3d, 0x00000008,
      :indirect_first_instance, 0x00000009,
      :shader_f16, 0x0000000A,
      :rg11b10_ufloat_renderable, 0x0000000B,
      :bgra8_unorm_storage, 0x0000000C,
      :float32_filterable, 0x0000000D,
      :float32_blendable, 0x0000000E,
      :clip_distances, 0x0000000F,
      :dual_source_blending, 0x00000010
    )
  end
end
