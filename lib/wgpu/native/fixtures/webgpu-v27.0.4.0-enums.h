/*
 * Generated from include/webgpu/webgpu.h in the official wgpu-native v27.0.4.0
 * release artifact. Only enum declarations consumed by AbiVerifier are kept.
 * Source SHA-256: a6fccf7f9f2fa674d1adfe4f6ea89784a876395b2307bfc2b06f2e77cf6cf356
 * Regenerate: bundle exec ruby script/update_abi_fixture.rb PATH_TO_WEBGPU_H
 */

typedef enum WGPUAdapterType {
    WGPUAdapterType_DiscreteGPU = 0x00000001,
    WGPUAdapterType_IntegratedGPU = 0x00000002,
    WGPUAdapterType_CPU = 0x00000003,
    WGPUAdapterType_Unknown = 0x00000004,
    WGPUAdapterType_Force32 = 0x7FFFFFFF
} WGPUAdapterType WGPU_ENUM_ATTRIBUTE;

typedef enum WGPUAddressMode {
    /**
     * `0x00000000`.
     * Indicates no value is passed for this argument. See @ref SentinelValues.
     */
    WGPUAddressMode_Undefined = 0x00000000,
    WGPUAddressMode_ClampToEdge = 0x00000001,
    WGPUAddressMode_Repeat = 0x00000002,
    WGPUAddressMode_MirrorRepeat = 0x00000003,
    WGPUAddressMode_Force32 = 0x7FFFFFFF
} WGPUAddressMode WGPU_ENUM_ATTRIBUTE;

typedef enum WGPUBackendType {
    /**
     * `0x00000000`.
     * Indicates no value is passed for this argument. See @ref SentinelValues.
     */
    WGPUBackendType_Undefined = 0x00000000,
    WGPUBackendType_Null = 0x00000001,
    WGPUBackendType_WebGPU = 0x00000002,
    WGPUBackendType_D3D11 = 0x00000003,
    WGPUBackendType_D3D12 = 0x00000004,
    WGPUBackendType_Metal = 0x00000005,
    WGPUBackendType_Vulkan = 0x00000006,
    WGPUBackendType_OpenGL = 0x00000007,
    WGPUBackendType_OpenGLES = 0x00000008,
    WGPUBackendType_Force32 = 0x7FFFFFFF
} WGPUBackendType WGPU_ENUM_ATTRIBUTE;

typedef enum WGPUBlendFactor {
    /**
     * `0x00000000`.
     * Indicates no value is passed for this argument. See @ref SentinelValues.
     */
    WGPUBlendFactor_Undefined = 0x00000000,
    WGPUBlendFactor_Zero = 0x00000001,
    WGPUBlendFactor_One = 0x00000002,
    WGPUBlendFactor_Src = 0x00000003,
    WGPUBlendFactor_OneMinusSrc = 0x00000004,
    WGPUBlendFactor_SrcAlpha = 0x00000005,
    WGPUBlendFactor_OneMinusSrcAlpha = 0x00000006,
    WGPUBlendFactor_Dst = 0x00000007,
    WGPUBlendFactor_OneMinusDst = 0x00000008,
    WGPUBlendFactor_DstAlpha = 0x00000009,
    WGPUBlendFactor_OneMinusDstAlpha = 0x0000000A,
    WGPUBlendFactor_SrcAlphaSaturated = 0x0000000B,
    WGPUBlendFactor_Constant = 0x0000000C,
    WGPUBlendFactor_OneMinusConstant = 0x0000000D,
    WGPUBlendFactor_Src1 = 0x0000000E,
    WGPUBlendFactor_OneMinusSrc1 = 0x0000000F,
    WGPUBlendFactor_Src1Alpha = 0x00000010,
    WGPUBlendFactor_OneMinusSrc1Alpha = 0x00000011,
    WGPUBlendFactor_Force32 = 0x7FFFFFFF
} WGPUBlendFactor WGPU_ENUM_ATTRIBUTE;

typedef enum WGPUBlendOperation {
    /**
     * `0x00000000`.
     * Indicates no value is passed for this argument. See @ref SentinelValues.
     */
    WGPUBlendOperation_Undefined = 0x00000000,
    WGPUBlendOperation_Add = 0x00000001,
    WGPUBlendOperation_Subtract = 0x00000002,
    WGPUBlendOperation_ReverseSubtract = 0x00000003,
    WGPUBlendOperation_Min = 0x00000004,
    WGPUBlendOperation_Max = 0x00000005,
    WGPUBlendOperation_Force32 = 0x7FFFFFFF
} WGPUBlendOperation WGPU_ENUM_ATTRIBUTE;

typedef enum WGPUBufferBindingType {
    /**
     * `0x00000000`.
     * Indicates that this @ref WGPUBufferBindingLayout member of
     * its parent @ref WGPUBindGroupLayoutEntry is not used.
     * (See also @ref SentinelValues.)
     */
    WGPUBufferBindingType_BindingNotUsed = 0x00000000,
    /**
     * `0x00000001`.
     * Indicates no value is passed for this argument. See @ref SentinelValues.
     */
    WGPUBufferBindingType_Undefined = 0x00000001,
    WGPUBufferBindingType_Uniform = 0x00000002,
    WGPUBufferBindingType_Storage = 0x00000003,
    WGPUBufferBindingType_ReadOnlyStorage = 0x00000004,
    WGPUBufferBindingType_Force32 = 0x7FFFFFFF
} WGPUBufferBindingType WGPU_ENUM_ATTRIBUTE;

typedef enum WGPUBufferMapState {
    WGPUBufferMapState_Unmapped = 0x00000001,
    WGPUBufferMapState_Pending = 0x00000002,
    WGPUBufferMapState_Mapped = 0x00000003,
    WGPUBufferMapState_Force32 = 0x7FFFFFFF
} WGPUBufferMapState WGPU_ENUM_ATTRIBUTE;

typedef enum WGPUCallbackMode {
    /**
     * `0x00000001`.
     * Callbacks created with `WGPUCallbackMode_WaitAnyOnly`:
     * - fire when the asynchronous operation's future is passed to a call to `::wgpuInstanceWaitAny`
     *   AND the operation has already completed or it completes inside the call to `::wgpuInstanceWaitAny`.
     */
    WGPUCallbackMode_WaitAnyOnly = 0x00000001,
    /**
     * `0x00000002`.
     * Callbacks created with `WGPUCallbackMode_AllowProcessEvents`:
     * - fire for the same reasons as callbacks created with `WGPUCallbackMode_WaitAnyOnly`
     * - fire inside a call to `::wgpuInstanceProcessEvents` if the asynchronous operation is complete.
     */
    WGPUCallbackMode_AllowProcessEvents = 0x00000002,
    /**
     * `0x00000003`.
     * Callbacks created with `WGPUCallbackMode_AllowSpontaneous`:
     * - fire for the same reasons as callbacks created with `WGPUCallbackMode_AllowProcessEvents`
     * - **may** fire spontaneously on an arbitrary or application thread, when the WebGPU implementations discovers that the asynchronous operation is complete.
     *
     *   Implementations _should_ fire spontaneous callbacks as soon as possible.
     *
     * @note Because spontaneous callbacks may fire at an arbitrary time on an arbitrary thread, applications should take extra care when acquiring locks or mutating state inside the callback. It undefined behavior to re-entrantly call into the webgpu.h API if the callback fires while inside the callstack of another webgpu.h function that is not `wgpuInstanceWaitAny` or `wgpuInstanceProcessEvents`.
     */
    WGPUCallbackMode_AllowSpontaneous = 0x00000003,
    WGPUCallbackMode_Force32 = 0x7FFFFFFF
} WGPUCallbackMode WGPU_ENUM_ATTRIBUTE;

typedef enum WGPUCompareFunction {
    /**
     * `0x00000000`.
     * Indicates no value is passed for this argument. See @ref SentinelValues.
     */
    WGPUCompareFunction_Undefined = 0x00000000,
    WGPUCompareFunction_Never = 0x00000001,
    WGPUCompareFunction_Less = 0x00000002,
    WGPUCompareFunction_Equal = 0x00000003,
    WGPUCompareFunction_LessEqual = 0x00000004,
    WGPUCompareFunction_Greater = 0x00000005,
    WGPUCompareFunction_NotEqual = 0x00000006,
    WGPUCompareFunction_GreaterEqual = 0x00000007,
    WGPUCompareFunction_Always = 0x00000008,
    WGPUCompareFunction_Force32 = 0x7FFFFFFF
} WGPUCompareFunction WGPU_ENUM_ATTRIBUTE;

typedef enum WGPUCompilationInfoRequestStatus {
    WGPUCompilationInfoRequestStatus_Success = 0x00000001,
    WGPUCompilationInfoRequestStatus_InstanceDropped = 0x00000002,
    WGPUCompilationInfoRequestStatus_Error = 0x00000003,
    WGPUCompilationInfoRequestStatus_Unknown = 0x00000004,
    WGPUCompilationInfoRequestStatus_Force32 = 0x7FFFFFFF
} WGPUCompilationInfoRequestStatus WGPU_ENUM_ATTRIBUTE;

typedef enum WGPUCompilationMessageType {
    WGPUCompilationMessageType_Error = 0x00000001,
    WGPUCompilationMessageType_Warning = 0x00000002,
    WGPUCompilationMessageType_Info = 0x00000003,
    WGPUCompilationMessageType_Force32 = 0x7FFFFFFF
} WGPUCompilationMessageType WGPU_ENUM_ATTRIBUTE;

typedef enum WGPUCompositeAlphaMode {
    /**
     * `0x00000000`.
     * Lets the WebGPU implementation choose the best mode (supported, and with the best performance) between @ref WGPUCompositeAlphaMode_Opaque or @ref WGPUCompositeAlphaMode_Inherit.
     */
    WGPUCompositeAlphaMode_Auto = 0x00000000,
    /**
     * `0x00000001`.
     * The alpha component of the image is ignored and teated as if it is always 1.0.
     */
    WGPUCompositeAlphaMode_Opaque = 0x00000001,
    /**
     * `0x00000002`.
     * The alpha component is respected and non-alpha components are assumed to be already multiplied with the alpha component. For example, (0.5, 0, 0, 0.5) is semi-transparent bright red.
     */
    WGPUCompositeAlphaMode_Premultiplied = 0x00000002,
    /**
     * `0x00000003`.
     * The alpha component is respected and non-alpha components are assumed to NOT be already multiplied with the alpha component. For example, (1.0, 0, 0, 0.5) is semi-transparent bright red.
     */
    WGPUCompositeAlphaMode_Unpremultiplied = 0x00000003,
    /**
     * `0x00000004`.
     * The handling of the alpha component is unknown to WebGPU and should be handled by the application using system-specific APIs. This mode may be unavailable (for example on Wasm).
     */
    WGPUCompositeAlphaMode_Inherit = 0x00000004,
    WGPUCompositeAlphaMode_Force32 = 0x7FFFFFFF
} WGPUCompositeAlphaMode WGPU_ENUM_ATTRIBUTE;

typedef enum WGPUCreatePipelineAsyncStatus {
    WGPUCreatePipelineAsyncStatus_Success = 0x00000001,
    WGPUCreatePipelineAsyncStatus_InstanceDropped = 0x00000002,
    WGPUCreatePipelineAsyncStatus_ValidationError = 0x00000003,
    WGPUCreatePipelineAsyncStatus_InternalError = 0x00000004,
    WGPUCreatePipelineAsyncStatus_Unknown = 0x00000005,
    WGPUCreatePipelineAsyncStatus_Force32 = 0x7FFFFFFF
} WGPUCreatePipelineAsyncStatus WGPU_ENUM_ATTRIBUTE;

typedef enum WGPUCullMode {
    /**
     * `0x00000000`.
     * Indicates no value is passed for this argument. See @ref SentinelValues.
     */
    WGPUCullMode_Undefined = 0x00000000,
    WGPUCullMode_None = 0x00000001,
    WGPUCullMode_Front = 0x00000002,
    WGPUCullMode_Back = 0x00000003,
    WGPUCullMode_Force32 = 0x7FFFFFFF
} WGPUCullMode WGPU_ENUM_ATTRIBUTE;

typedef enum WGPUDeviceLostReason {
    WGPUDeviceLostReason_Unknown = 0x00000001,
    WGPUDeviceLostReason_Destroyed = 0x00000002,
    WGPUDeviceLostReason_InstanceDropped = 0x00000003,
    WGPUDeviceLostReason_FailedCreation = 0x00000004,
    WGPUDeviceLostReason_Force32 = 0x7FFFFFFF
} WGPUDeviceLostReason WGPU_ENUM_ATTRIBUTE;

typedef enum WGPUErrorFilter {
    WGPUErrorFilter_Validation = 0x00000001,
    WGPUErrorFilter_OutOfMemory = 0x00000002,
    WGPUErrorFilter_Internal = 0x00000003,
    WGPUErrorFilter_Force32 = 0x7FFFFFFF
} WGPUErrorFilter WGPU_ENUM_ATTRIBUTE;

typedef enum WGPUErrorType {
    WGPUErrorType_NoError = 0x00000001,
    WGPUErrorType_Validation = 0x00000002,
    WGPUErrorType_OutOfMemory = 0x00000003,
    WGPUErrorType_Internal = 0x00000004,
    WGPUErrorType_Unknown = 0x00000005,
    WGPUErrorType_Force32 = 0x7FFFFFFF
} WGPUErrorType WGPU_ENUM_ATTRIBUTE;

typedef enum WGPUFeatureLevel {
    /**
     * `0x00000001`.
     * "Compatibility" profile which can be supported on OpenGL ES 3.1.
     */
    WGPUFeatureLevel_Compatibility = 0x00000001,
    /**
     * `0x00000002`.
     * "Core" profile which can be supported on Vulkan/Metal/D3D12.
     */
    WGPUFeatureLevel_Core = 0x00000002,
    WGPUFeatureLevel_Force32 = 0x7FFFFFFF
} WGPUFeatureLevel WGPU_ENUM_ATTRIBUTE;

typedef enum WGPUFeatureName {
    WGPUFeatureName_Undefined = 0x00000000,
    WGPUFeatureName_DepthClipControl = 0x00000001,
    WGPUFeatureName_Depth32FloatStencil8 = 0x00000002,
    WGPUFeatureName_TimestampQuery = 0x00000003,
    WGPUFeatureName_TextureCompressionBC = 0x00000004,
    WGPUFeatureName_TextureCompressionBCSliced3D = 0x00000005,
    WGPUFeatureName_TextureCompressionETC2 = 0x00000006,
    WGPUFeatureName_TextureCompressionASTC = 0x00000007,
    WGPUFeatureName_TextureCompressionASTCSliced3D = 0x00000008,
    WGPUFeatureName_IndirectFirstInstance = 0x00000009,
    WGPUFeatureName_ShaderF16 = 0x0000000A,
    WGPUFeatureName_RG11B10UfloatRenderable = 0x0000000B,
    WGPUFeatureName_BGRA8UnormStorage = 0x0000000C,
    WGPUFeatureName_Float32Filterable = 0x0000000D,
    WGPUFeatureName_Float32Blendable = 0x0000000E,
    WGPUFeatureName_ClipDistances = 0x0000000F,
    WGPUFeatureName_DualSourceBlending = 0x00000010,
    WGPUFeatureName_Force32 = 0x7FFFFFFF
} WGPUFeatureName WGPU_ENUM_ATTRIBUTE;

typedef enum WGPUFilterMode {
    /**
     * `0x00000000`.
     * Indicates no value is passed for this argument. See @ref SentinelValues.
     */
    WGPUFilterMode_Undefined = 0x00000000,
    WGPUFilterMode_Nearest = 0x00000001,
    WGPUFilterMode_Linear = 0x00000002,
    WGPUFilterMode_Force32 = 0x7FFFFFFF
} WGPUFilterMode WGPU_ENUM_ATTRIBUTE;

typedef enum WGPUFrontFace {
    /**
     * `0x00000000`.
     * Indicates no value is passed for this argument. See @ref SentinelValues.
     */
    WGPUFrontFace_Undefined = 0x00000000,
    WGPUFrontFace_CCW = 0x00000001,
    WGPUFrontFace_CW = 0x00000002,
    WGPUFrontFace_Force32 = 0x7FFFFFFF
} WGPUFrontFace WGPU_ENUM_ATTRIBUTE;

typedef enum WGPUIndexFormat {
    /**
     * `0x00000000`.
     * Indicates no value is passed for this argument. See @ref SentinelValues.
     */
    WGPUIndexFormat_Undefined = 0x00000000,
    WGPUIndexFormat_Uint16 = 0x00000001,
    WGPUIndexFormat_Uint32 = 0x00000002,
    WGPUIndexFormat_Force32 = 0x7FFFFFFF
} WGPUIndexFormat WGPU_ENUM_ATTRIBUTE;

typedef enum WGPULoadOp {
    /**
     * `0x00000000`.
     * Indicates no value is passed for this argument. See @ref SentinelValues.
     */
    WGPULoadOp_Undefined = 0x00000000,
    WGPULoadOp_Load = 0x00000001,
    WGPULoadOp_Clear = 0x00000002,
    WGPULoadOp_Force32 = 0x7FFFFFFF
} WGPULoadOp WGPU_ENUM_ATTRIBUTE;

typedef enum WGPUMapAsyncStatus {
    WGPUMapAsyncStatus_Success = 0x00000001,
    WGPUMapAsyncStatus_InstanceDropped = 0x00000002,
    WGPUMapAsyncStatus_Error = 0x00000003,
    WGPUMapAsyncStatus_Aborted = 0x00000004,
    WGPUMapAsyncStatus_Unknown = 0x00000005,
    WGPUMapAsyncStatus_Force32 = 0x7FFFFFFF
} WGPUMapAsyncStatus WGPU_ENUM_ATTRIBUTE;

typedef enum WGPUMipmapFilterMode {
    /**
     * `0x00000000`.
     * Indicates no value is passed for this argument. See @ref SentinelValues.
     */
    WGPUMipmapFilterMode_Undefined = 0x00000000,
    WGPUMipmapFilterMode_Nearest = 0x00000001,
    WGPUMipmapFilterMode_Linear = 0x00000002,
    WGPUMipmapFilterMode_Force32 = 0x7FFFFFFF
} WGPUMipmapFilterMode WGPU_ENUM_ATTRIBUTE;

typedef enum WGPUOptionalBool {
    WGPUOptionalBool_False = 0x00000000,
    WGPUOptionalBool_True = 0x00000001,
    WGPUOptionalBool_Undefined = 0x00000002,
    WGPUOptionalBool_Force32 = 0x7FFFFFFF
} WGPUOptionalBool WGPU_ENUM_ATTRIBUTE;

typedef enum WGPUPopErrorScopeStatus {
    /**
     * `0x00000001`.
     * The error scope stack was successfully popped and a result was reported.
     */
    WGPUPopErrorScopeStatus_Success = 0x00000001,
    WGPUPopErrorScopeStatus_InstanceDropped = 0x00000002,
    /**
     * `0x00000003`.
     * The error scope stack could not be popped, because it was empty.
     */
    WGPUPopErrorScopeStatus_EmptyStack = 0x00000003,
    WGPUPopErrorScopeStatus_Force32 = 0x7FFFFFFF
} WGPUPopErrorScopeStatus WGPU_ENUM_ATTRIBUTE;

typedef enum WGPUPowerPreference {
    /**
     * `0x00000000`.
     * No preference. (See also @ref SentinelValues.)
     */
    WGPUPowerPreference_Undefined = 0x00000000,
    WGPUPowerPreference_LowPower = 0x00000001,
    WGPUPowerPreference_HighPerformance = 0x00000002,
    WGPUPowerPreference_Force32 = 0x7FFFFFFF
} WGPUPowerPreference WGPU_ENUM_ATTRIBUTE;

typedef enum WGPUPresentMode {
    /**
     * `0x00000000`.
     * Present mode is not specified. Use the default.
     */
    WGPUPresentMode_Undefined = 0x00000000,
    /**
     * `0x00000001`.
     * The presentation of the image to the user waits for the next vertical blanking period to update in a first-in, first-out manner.
     * Tearing cannot be observed and frame-loop will be limited to the display's refresh rate.
     * This is the only mode that's always available.
     */
    WGPUPresentMode_Fifo = 0x00000001,
    /**
     * `0x00000002`.
     * The presentation of the image to the user tries to wait for the next vertical blanking period but may decide to not wait if a frame is presented late.
     * Tearing can sometimes be observed but late-frame don't produce a full-frame stutter in the presentation.
     * This is still a first-in, first-out mechanism so a frame-loop will be limited to the display's refresh rate.
     */
    WGPUPresentMode_FifoRelaxed = 0x00000002,
    /**
     * `0x00000003`.
     * The presentation of the image to the user is updated immediately without waiting for a vertical blank.
     * Tearing can be observed but latency is minimized.
     */
    WGPUPresentMode_Immediate = 0x00000003,
    /**
     * `0x00000004`.
     * The presentation of the image to the user waits for the next vertical blanking period to update to the latest provided image.
     * Tearing cannot be observed and a frame-loop is not limited to the display's refresh rate.
     */
    WGPUPresentMode_Mailbox = 0x00000004,
    WGPUPresentMode_Force32 = 0x7FFFFFFF
} WGPUPresentMode WGPU_ENUM_ATTRIBUTE;

typedef enum WGPUPrimitiveTopology {
    /**
     * `0x00000000`.
     * Indicates no value is passed for this argument. See @ref SentinelValues.
     */
    WGPUPrimitiveTopology_Undefined = 0x00000000,
    WGPUPrimitiveTopology_PointList = 0x00000001,
    WGPUPrimitiveTopology_LineList = 0x00000002,
    WGPUPrimitiveTopology_LineStrip = 0x00000003,
    WGPUPrimitiveTopology_TriangleList = 0x00000004,
    WGPUPrimitiveTopology_TriangleStrip = 0x00000005,
    WGPUPrimitiveTopology_Force32 = 0x7FFFFFFF
} WGPUPrimitiveTopology WGPU_ENUM_ATTRIBUTE;

typedef enum WGPUQueryType {
    WGPUQueryType_Occlusion = 0x00000001,
    WGPUQueryType_Timestamp = 0x00000002,
    WGPUQueryType_Force32 = 0x7FFFFFFF
} WGPUQueryType WGPU_ENUM_ATTRIBUTE;

typedef enum WGPUQueueWorkDoneStatus {
    WGPUQueueWorkDoneStatus_Success = 0x00000001,
    WGPUQueueWorkDoneStatus_InstanceDropped = 0x00000002,
    WGPUQueueWorkDoneStatus_Error = 0x00000003,
    WGPUQueueWorkDoneStatus_Unknown = 0x00000004,
    WGPUQueueWorkDoneStatus_Force32 = 0x7FFFFFFF
} WGPUQueueWorkDoneStatus WGPU_ENUM_ATTRIBUTE;

typedef enum WGPURequestAdapterStatus {
    WGPURequestAdapterStatus_Success = 0x00000001,
    WGPURequestAdapterStatus_InstanceDropped = 0x00000002,
    WGPURequestAdapterStatus_Unavailable = 0x00000003,
    WGPURequestAdapterStatus_Error = 0x00000004,
    WGPURequestAdapterStatus_Unknown = 0x00000005,
    WGPURequestAdapterStatus_Force32 = 0x7FFFFFFF
} WGPURequestAdapterStatus WGPU_ENUM_ATTRIBUTE;

typedef enum WGPURequestDeviceStatus {
    WGPURequestDeviceStatus_Success = 0x00000001,
    WGPURequestDeviceStatus_InstanceDropped = 0x00000002,
    WGPURequestDeviceStatus_Error = 0x00000003,
    WGPURequestDeviceStatus_Unknown = 0x00000004,
    WGPURequestDeviceStatus_Force32 = 0x7FFFFFFF
} WGPURequestDeviceStatus WGPU_ENUM_ATTRIBUTE;

typedef enum WGPUSType {
    WGPUSType_ShaderSourceSPIRV = 0x00000001,
    WGPUSType_ShaderSourceWGSL = 0x00000002,
    WGPUSType_RenderPassMaxDrawCount = 0x00000003,
    WGPUSType_SurfaceSourceMetalLayer = 0x00000004,
    WGPUSType_SurfaceSourceWindowsHWND = 0x00000005,
    WGPUSType_SurfaceSourceXlibWindow = 0x00000006,
    WGPUSType_SurfaceSourceWaylandSurface = 0x00000007,
    WGPUSType_SurfaceSourceAndroidNativeWindow = 0x00000008,
    WGPUSType_SurfaceSourceXCBWindow = 0x00000009,
    WGPUSType_Force32 = 0x7FFFFFFF
} WGPUSType WGPU_ENUM_ATTRIBUTE;

typedef enum WGPUSamplerBindingType {
    /**
     * `0x00000000`.
     * Indicates that this @ref WGPUSamplerBindingLayout member of
     * its parent @ref WGPUBindGroupLayoutEntry is not used.
     * (See also @ref SentinelValues.)
     */
    WGPUSamplerBindingType_BindingNotUsed = 0x00000000,
    /**
     * `0x00000001`.
     * Indicates no value is passed for this argument. See @ref SentinelValues.
     */
    WGPUSamplerBindingType_Undefined = 0x00000001,
    WGPUSamplerBindingType_Filtering = 0x00000002,
    WGPUSamplerBindingType_NonFiltering = 0x00000003,
    WGPUSamplerBindingType_Comparison = 0x00000004,
    WGPUSamplerBindingType_Force32 = 0x7FFFFFFF
} WGPUSamplerBindingType WGPU_ENUM_ATTRIBUTE;

typedef enum WGPUStatus {
    WGPUStatus_Success = 0x00000001,
    WGPUStatus_Error = 0x00000002,
    WGPUStatus_Force32 = 0x7FFFFFFF
} WGPUStatus WGPU_ENUM_ATTRIBUTE;

typedef enum WGPUStencilOperation {
    /**
     * `0x00000000`.
     * Indicates no value is passed for this argument. See @ref SentinelValues.
     */
    WGPUStencilOperation_Undefined = 0x00000000,
    WGPUStencilOperation_Keep = 0x00000001,
    WGPUStencilOperation_Zero = 0x00000002,
    WGPUStencilOperation_Replace = 0x00000003,
    WGPUStencilOperation_Invert = 0x00000004,
    WGPUStencilOperation_IncrementClamp = 0x00000005,
    WGPUStencilOperation_DecrementClamp = 0x00000006,
    WGPUStencilOperation_IncrementWrap = 0x00000007,
    WGPUStencilOperation_DecrementWrap = 0x00000008,
    WGPUStencilOperation_Force32 = 0x7FFFFFFF
} WGPUStencilOperation WGPU_ENUM_ATTRIBUTE;

typedef enum WGPUStorageTextureAccess {
    /**
     * `0x00000000`.
     * Indicates that this @ref WGPUStorageTextureBindingLayout member of
     * its parent @ref WGPUBindGroupLayoutEntry is not used.
     * (See also @ref SentinelValues.)
     */
    WGPUStorageTextureAccess_BindingNotUsed = 0x00000000,
    /**
     * `0x00000001`.
     * Indicates no value is passed for this argument. See @ref SentinelValues.
     */
    WGPUStorageTextureAccess_Undefined = 0x00000001,
    WGPUStorageTextureAccess_WriteOnly = 0x00000002,
    WGPUStorageTextureAccess_ReadOnly = 0x00000003,
    WGPUStorageTextureAccess_ReadWrite = 0x00000004,
    WGPUStorageTextureAccess_Force32 = 0x7FFFFFFF
} WGPUStorageTextureAccess WGPU_ENUM_ATTRIBUTE;

typedef enum WGPUStoreOp {
    /**
     * `0x00000000`.
     * Indicates no value is passed for this argument. See @ref SentinelValues.
     */
    WGPUStoreOp_Undefined = 0x00000000,
    WGPUStoreOp_Store = 0x00000001,
    WGPUStoreOp_Discard = 0x00000002,
    WGPUStoreOp_Force32 = 0x7FFFFFFF
} WGPUStoreOp WGPU_ENUM_ATTRIBUTE;

typedef enum WGPUSurfaceGetCurrentTextureStatus {
    /**
     * `0x00000001`.
     * Yay! Everything is good and we can render this frame.
     */
    WGPUSurfaceGetCurrentTextureStatus_SuccessOptimal = 0x00000001,
    /**
     * `0x00000002`.
     * Still OK - the surface can present the frame, but in a suboptimal way. The surface may need reconfiguration.
     */
    WGPUSurfaceGetCurrentTextureStatus_SuccessSuboptimal = 0x00000002,
    /**
     * `0x00000003`.
     * Some operation timed out while trying to acquire the frame.
     */
    WGPUSurfaceGetCurrentTextureStatus_Timeout = 0x00000003,
    /**
     * `0x00000004`.
     * The surface is too different to be used, compared to when it was originally created.
     */
    WGPUSurfaceGetCurrentTextureStatus_Outdated = 0x00000004,
    /**
     * `0x00000005`.
     * The connection to whatever owns the surface was lost.
     */
    WGPUSurfaceGetCurrentTextureStatus_Lost = 0x00000005,
    /**
     * `0x00000006`.
     * The system ran out of memory.
     */
    WGPUSurfaceGetCurrentTextureStatus_OutOfMemory = 0x00000006,
    /**
     * `0x00000007`.
     * The @ref WGPUDevice configured on the @ref WGPUSurface was lost.
     */
    WGPUSurfaceGetCurrentTextureStatus_DeviceLost = 0x00000007,
    /**
     * `0x00000008`.
     * The surface is not configured, or there was an @ref OutStructChainError.
     */
    WGPUSurfaceGetCurrentTextureStatus_Error = 0x00000008,
    WGPUSurfaceGetCurrentTextureStatus_Force32 = 0x7FFFFFFF
} WGPUSurfaceGetCurrentTextureStatus WGPU_ENUM_ATTRIBUTE;

typedef enum WGPUTextureAspect {
    /**
     * `0x00000000`.
     * Indicates no value is passed for this argument. See @ref SentinelValues.
     */
    WGPUTextureAspect_Undefined = 0x00000000,
    WGPUTextureAspect_All = 0x00000001,
    WGPUTextureAspect_StencilOnly = 0x00000002,
    WGPUTextureAspect_DepthOnly = 0x00000003,
    WGPUTextureAspect_Force32 = 0x7FFFFFFF
} WGPUTextureAspect WGPU_ENUM_ATTRIBUTE;

typedef enum WGPUTextureDimension {
    /**
     * `0x00000000`.
     * Indicates no value is passed for this argument. See @ref SentinelValues.
     */
    WGPUTextureDimension_Undefined = 0x00000000,
    WGPUTextureDimension_1D = 0x00000001,
    WGPUTextureDimension_2D = 0x00000002,
    WGPUTextureDimension_3D = 0x00000003,
    WGPUTextureDimension_Force32 = 0x7FFFFFFF
} WGPUTextureDimension WGPU_ENUM_ATTRIBUTE;

typedef enum WGPUTextureFormat {
    /**
     * `0x00000000`.
     * Indicates no value is passed for this argument. See @ref SentinelValues.
     */
    WGPUTextureFormat_Undefined = 0x00000000,
    WGPUTextureFormat_R8Unorm = 0x00000001,
    WGPUTextureFormat_R8Snorm = 0x00000002,
    WGPUTextureFormat_R8Uint = 0x00000003,
    WGPUTextureFormat_R8Sint = 0x00000004,
    WGPUTextureFormat_R16Uint = 0x00000005,
    WGPUTextureFormat_R16Sint = 0x00000006,
    WGPUTextureFormat_R16Float = 0x00000007,
    WGPUTextureFormat_RG8Unorm = 0x00000008,
    WGPUTextureFormat_RG8Snorm = 0x00000009,
    WGPUTextureFormat_RG8Uint = 0x0000000A,
    WGPUTextureFormat_RG8Sint = 0x0000000B,
    WGPUTextureFormat_R32Float = 0x0000000C,
    WGPUTextureFormat_R32Uint = 0x0000000D,
    WGPUTextureFormat_R32Sint = 0x0000000E,
    WGPUTextureFormat_RG16Uint = 0x0000000F,
    WGPUTextureFormat_RG16Sint = 0x00000010,
    WGPUTextureFormat_RG16Float = 0x00000011,
    WGPUTextureFormat_RGBA8Unorm = 0x00000012,
    WGPUTextureFormat_RGBA8UnormSrgb = 0x00000013,
    WGPUTextureFormat_RGBA8Snorm = 0x00000014,
    WGPUTextureFormat_RGBA8Uint = 0x00000015,
    WGPUTextureFormat_RGBA8Sint = 0x00000016,
    WGPUTextureFormat_BGRA8Unorm = 0x00000017,
    WGPUTextureFormat_BGRA8UnormSrgb = 0x00000018,
    WGPUTextureFormat_RGB10A2Uint = 0x00000019,
    WGPUTextureFormat_RGB10A2Unorm = 0x0000001A,
    WGPUTextureFormat_RG11B10Ufloat = 0x0000001B,
    WGPUTextureFormat_RGB9E5Ufloat = 0x0000001C,
    WGPUTextureFormat_RG32Float = 0x0000001D,
    WGPUTextureFormat_RG32Uint = 0x0000001E,
    WGPUTextureFormat_RG32Sint = 0x0000001F,
    WGPUTextureFormat_RGBA16Uint = 0x00000020,
    WGPUTextureFormat_RGBA16Sint = 0x00000021,
    WGPUTextureFormat_RGBA16Float = 0x00000022,
    WGPUTextureFormat_RGBA32Float = 0x00000023,
    WGPUTextureFormat_RGBA32Uint = 0x00000024,
    WGPUTextureFormat_RGBA32Sint = 0x00000025,
    WGPUTextureFormat_Stencil8 = 0x00000026,
    WGPUTextureFormat_Depth16Unorm = 0x00000027,
    WGPUTextureFormat_Depth24Plus = 0x00000028,
    WGPUTextureFormat_Depth24PlusStencil8 = 0x00000029,
    WGPUTextureFormat_Depth32Float = 0x0000002A,
    WGPUTextureFormat_Depth32FloatStencil8 = 0x0000002B,
    WGPUTextureFormat_BC1RGBAUnorm = 0x0000002C,
    WGPUTextureFormat_BC1RGBAUnormSrgb = 0x0000002D,
    WGPUTextureFormat_BC2RGBAUnorm = 0x0000002E,
    WGPUTextureFormat_BC2RGBAUnormSrgb = 0x0000002F,
    WGPUTextureFormat_BC3RGBAUnorm = 0x00000030,
    WGPUTextureFormat_BC3RGBAUnormSrgb = 0x00000031,
    WGPUTextureFormat_BC4RUnorm = 0x00000032,
    WGPUTextureFormat_BC4RSnorm = 0x00000033,
    WGPUTextureFormat_BC5RGUnorm = 0x00000034,
    WGPUTextureFormat_BC5RGSnorm = 0x00000035,
    WGPUTextureFormat_BC6HRGBUfloat = 0x00000036,
    WGPUTextureFormat_BC6HRGBFloat = 0x00000037,
    WGPUTextureFormat_BC7RGBAUnorm = 0x00000038,
    WGPUTextureFormat_BC7RGBAUnormSrgb = 0x00000039,
    WGPUTextureFormat_ETC2RGB8Unorm = 0x0000003A,
    WGPUTextureFormat_ETC2RGB8UnormSrgb = 0x0000003B,
    WGPUTextureFormat_ETC2RGB8A1Unorm = 0x0000003C,
    WGPUTextureFormat_ETC2RGB8A1UnormSrgb = 0x0000003D,
    WGPUTextureFormat_ETC2RGBA8Unorm = 0x0000003E,
    WGPUTextureFormat_ETC2RGBA8UnormSrgb = 0x0000003F,
    WGPUTextureFormat_EACR11Unorm = 0x00000040,
    WGPUTextureFormat_EACR11Snorm = 0x00000041,
    WGPUTextureFormat_EACRG11Unorm = 0x00000042,
    WGPUTextureFormat_EACRG11Snorm = 0x00000043,
    WGPUTextureFormat_ASTC4x4Unorm = 0x00000044,
    WGPUTextureFormat_ASTC4x4UnormSrgb = 0x00000045,
    WGPUTextureFormat_ASTC5x4Unorm = 0x00000046,
    WGPUTextureFormat_ASTC5x4UnormSrgb = 0x00000047,
    WGPUTextureFormat_ASTC5x5Unorm = 0x00000048,
    WGPUTextureFormat_ASTC5x5UnormSrgb = 0x00000049,
    WGPUTextureFormat_ASTC6x5Unorm = 0x0000004A,
    WGPUTextureFormat_ASTC6x5UnormSrgb = 0x0000004B,
    WGPUTextureFormat_ASTC6x6Unorm = 0x0000004C,
    WGPUTextureFormat_ASTC6x6UnormSrgb = 0x0000004D,
    WGPUTextureFormat_ASTC8x5Unorm = 0x0000004E,
    WGPUTextureFormat_ASTC8x5UnormSrgb = 0x0000004F,
    WGPUTextureFormat_ASTC8x6Unorm = 0x00000050,
    WGPUTextureFormat_ASTC8x6UnormSrgb = 0x00000051,
    WGPUTextureFormat_ASTC8x8Unorm = 0x00000052,
    WGPUTextureFormat_ASTC8x8UnormSrgb = 0x00000053,
    WGPUTextureFormat_ASTC10x5Unorm = 0x00000054,
    WGPUTextureFormat_ASTC10x5UnormSrgb = 0x00000055,
    WGPUTextureFormat_ASTC10x6Unorm = 0x00000056,
    WGPUTextureFormat_ASTC10x6UnormSrgb = 0x00000057,
    WGPUTextureFormat_ASTC10x8Unorm = 0x00000058,
    WGPUTextureFormat_ASTC10x8UnormSrgb = 0x00000059,
    WGPUTextureFormat_ASTC10x10Unorm = 0x0000005A,
    WGPUTextureFormat_ASTC10x10UnormSrgb = 0x0000005B,
    WGPUTextureFormat_ASTC12x10Unorm = 0x0000005C,
    WGPUTextureFormat_ASTC12x10UnormSrgb = 0x0000005D,
    WGPUTextureFormat_ASTC12x12Unorm = 0x0000005E,
    WGPUTextureFormat_ASTC12x12UnormSrgb = 0x0000005F,
    WGPUTextureFormat_Force32 = 0x7FFFFFFF
} WGPUTextureFormat WGPU_ENUM_ATTRIBUTE;

typedef enum WGPUTextureSampleType {
    /**
     * `0x00000000`.
     * Indicates that this @ref WGPUTextureBindingLayout member of
     * its parent @ref WGPUBindGroupLayoutEntry is not used.
     * (See also @ref SentinelValues.)
     */
    WGPUTextureSampleType_BindingNotUsed = 0x00000000,
    /**
     * `0x00000001`.
     * Indicates no value is passed for this argument. See @ref SentinelValues.
     */
    WGPUTextureSampleType_Undefined = 0x00000001,
    WGPUTextureSampleType_Float = 0x00000002,
    WGPUTextureSampleType_UnfilterableFloat = 0x00000003,
    WGPUTextureSampleType_Depth = 0x00000004,
    WGPUTextureSampleType_Sint = 0x00000005,
    WGPUTextureSampleType_Uint = 0x00000006,
    WGPUTextureSampleType_Force32 = 0x7FFFFFFF
} WGPUTextureSampleType WGPU_ENUM_ATTRIBUTE;

typedef enum WGPUTextureViewDimension {
    /**
     * `0x00000000`.
     * Indicates no value is passed for this argument. See @ref SentinelValues.
     */
    WGPUTextureViewDimension_Undefined = 0x00000000,
    WGPUTextureViewDimension_1D = 0x00000001,
    WGPUTextureViewDimension_2D = 0x00000002,
    WGPUTextureViewDimension_2DArray = 0x00000003,
    WGPUTextureViewDimension_Cube = 0x00000004,
    WGPUTextureViewDimension_CubeArray = 0x00000005,
    WGPUTextureViewDimension_3D = 0x00000006,
    WGPUTextureViewDimension_Force32 = 0x7FFFFFFF
} WGPUTextureViewDimension WGPU_ENUM_ATTRIBUTE;

typedef enum WGPUVertexFormat {
    WGPUVertexFormat_Uint8 = 0x00000001,
    WGPUVertexFormat_Uint8x2 = 0x00000002,
    WGPUVertexFormat_Uint8x4 = 0x00000003,
    WGPUVertexFormat_Sint8 = 0x00000004,
    WGPUVertexFormat_Sint8x2 = 0x00000005,
    WGPUVertexFormat_Sint8x4 = 0x00000006,
    WGPUVertexFormat_Unorm8 = 0x00000007,
    WGPUVertexFormat_Unorm8x2 = 0x00000008,
    WGPUVertexFormat_Unorm8x4 = 0x00000009,
    WGPUVertexFormat_Snorm8 = 0x0000000A,
    WGPUVertexFormat_Snorm8x2 = 0x0000000B,
    WGPUVertexFormat_Snorm8x4 = 0x0000000C,
    WGPUVertexFormat_Uint16 = 0x0000000D,
    WGPUVertexFormat_Uint16x2 = 0x0000000E,
    WGPUVertexFormat_Uint16x4 = 0x0000000F,
    WGPUVertexFormat_Sint16 = 0x00000010,
    WGPUVertexFormat_Sint16x2 = 0x00000011,
    WGPUVertexFormat_Sint16x4 = 0x00000012,
    WGPUVertexFormat_Unorm16 = 0x00000013,
    WGPUVertexFormat_Unorm16x2 = 0x00000014,
    WGPUVertexFormat_Unorm16x4 = 0x00000015,
    WGPUVertexFormat_Snorm16 = 0x00000016,
    WGPUVertexFormat_Snorm16x2 = 0x00000017,
    WGPUVertexFormat_Snorm16x4 = 0x00000018,
    WGPUVertexFormat_Float16 = 0x00000019,
    WGPUVertexFormat_Float16x2 = 0x0000001A,
    WGPUVertexFormat_Float16x4 = 0x0000001B,
    WGPUVertexFormat_Float32 = 0x0000001C,
    WGPUVertexFormat_Float32x2 = 0x0000001D,
    WGPUVertexFormat_Float32x3 = 0x0000001E,
    WGPUVertexFormat_Float32x4 = 0x0000001F,
    WGPUVertexFormat_Uint32 = 0x00000020,
    WGPUVertexFormat_Uint32x2 = 0x00000021,
    WGPUVertexFormat_Uint32x3 = 0x00000022,
    WGPUVertexFormat_Uint32x4 = 0x00000023,
    WGPUVertexFormat_Sint32 = 0x00000024,
    WGPUVertexFormat_Sint32x2 = 0x00000025,
    WGPUVertexFormat_Sint32x3 = 0x00000026,
    WGPUVertexFormat_Sint32x4 = 0x00000027,
    WGPUVertexFormat_Unorm10_10_10_2 = 0x00000028,
    WGPUVertexFormat_Unorm8x4BGRA = 0x00000029,
    WGPUVertexFormat_Force32 = 0x7FFFFFFF
} WGPUVertexFormat WGPU_ENUM_ATTRIBUTE;

typedef enum WGPUVertexStepMode {
    /**
     * `0x00000000`.
     * This @ref WGPUVertexBufferLayout is a "hole" in the @ref WGPUVertexState `buffers` array.
     * (See also @ref SentinelValues.)
     */
    WGPUVertexStepMode_VertexBufferNotUsed = 0x00000000,
    /**
     * `0x00000001`.
     * Indicates no value is passed for this argument. See @ref SentinelValues.
     */
    WGPUVertexStepMode_Undefined = 0x00000001,
    WGPUVertexStepMode_Vertex = 0x00000002,
    WGPUVertexStepMode_Instance = 0x00000003,
    WGPUVertexStepMode_Force32 = 0x7FFFFFFF
} WGPUVertexStepMode WGPU_ENUM_ATTRIBUTE;

typedef enum WGPUWGSLLanguageFeatureName {
    WGPUWGSLLanguageFeatureName_ReadonlyAndReadwriteStorageTextures = 0x00000001,
    WGPUWGSLLanguageFeatureName_Packed4x8IntegerDotProduct = 0x00000002,
    WGPUWGSLLanguageFeatureName_UnrestrictedPointerParameters = 0x00000003,
    WGPUWGSLLanguageFeatureName_PointerCompositeAccess = 0x00000004,
    WGPUWGSLLanguageFeatureName_Force32 = 0x7FFFFFFF
} WGPUWGSLLanguageFeatureName WGPU_ENUM_ATTRIBUTE;

typedef enum WGPUWaitStatus {
    /**
     * `0x00000001`.
     * At least one WGPUFuture completed successfully.
     */
    WGPUWaitStatus_Success = 0x00000001,
    /**
     * `0x00000002`.
     * No WGPUFutures completed within the timeout.
     */
    WGPUWaitStatus_TimedOut = 0x00000002,
    /**
     * `0x00000003`.
     * A @ref Timed-Wait was performed when WGPUInstanceFeatures::timedWaitAnyEnable is false.
     */
    WGPUWaitStatus_UnsupportedTimeout = 0x00000003,
    /**
     * `0x00000004`.
     * The number of futures waited on in a @ref Timed-Wait is greater than the supported WGPUInstanceFeatures::timedWaitAnyMaxCount.
     */
    WGPUWaitStatus_UnsupportedCount = 0x00000004,
    /**
     * `0x00000005`.
     * An invalid wait was performed with @ref Mixed-Sources.
     */
    WGPUWaitStatus_UnsupportedMixedSources = 0x00000005,
    WGPUWaitStatus_Force32 = 0x7FFFFFFF
} WGPUWaitStatus WGPU_ENUM_ATTRIBUTE;
