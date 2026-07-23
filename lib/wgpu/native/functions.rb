# frozen_string_literal: true

module WGPU
  module Native
    attach_function :wgpuCreateInstance,
                    [InstanceDescriptor.by_ref], :pointer

    attach_function :wgpuInstanceRelease,
                    [:pointer], :void

    attach_function :wgpuInstanceRequestAdapter,
                    [:pointer, RequestAdapterOptions.by_ref, RequestAdapterCallbackInfo.by_value], Future.by_value

    attach_function :wgpuInstanceEnumerateAdapters,
                    [:pointer, :pointer, :pointer], :size_t

    attach_function :wgpuInstanceProcessEvents,
                    [:pointer], :void

    attach_optional_function :wgpuInstanceWaitAny,
                             [:pointer, :size_t, :pointer, :uint64], WaitStatus

    attach_function :wgpuAdapterRelease,
                    [:pointer], :void

    attach_function :wgpuAdapterGetInfo,
                    [:pointer, AdapterInfo.by_ref], :void

    attach_function :wgpuAdapterRequestDevice,
                    [:pointer, DeviceDescriptor.by_ref, RequestDeviceCallbackInfo.by_value], Future.by_value

    attach_function :wgpuAdapterGetFeatures,
                    [:pointer, :pointer], :void

    attach_function :wgpuAdapterGetLimits,
                    [:pointer, :pointer], :uint32

    attach_function :wgpuDeviceRelease,
                    [:pointer], :void

    attach_function :wgpuDeviceDestroy,
                    [:pointer], :void

    attach_function :wgpuDeviceGetQueue,
                    [:pointer], :pointer

    attach_function :wgpuDeviceCreateBuffer,
                    [:pointer, BufferDescriptor.by_ref], :pointer

    attach_function :wgpuDeviceCreateTexture,
                    [:pointer, TextureDescriptor.by_ref], :pointer

    attach_function :wgpuDeviceCreateSampler,
                    [:pointer, :pointer], :pointer

    attach_function :wgpuDeviceCreateShaderModule,
                    [:pointer, ShaderModuleDescriptor.by_ref], :pointer

    attach_function :wgpuDeviceCreateBindGroupLayout,
                    [:pointer, BindGroupLayoutDescriptor.by_ref], :pointer

    attach_function :wgpuDeviceCreateBindGroup,
                    [:pointer, BindGroupDescriptor.by_ref], :pointer

    attach_function :wgpuDeviceCreatePipelineLayout,
                    [:pointer, PipelineLayoutDescriptor.by_ref], :pointer

    attach_function :wgpuDeviceCreateRenderPipeline,
                    [:pointer, :pointer], :pointer

    attach_function :wgpuDeviceCreateComputePipeline,
                    [:pointer, ComputePipelineDescriptor.by_ref], :pointer

    attach_function :wgpuDeviceCreateCommandEncoder,
                    [:pointer, CommandEncoderDescriptor.by_ref], :pointer

    attach_optional_function :wgpuDevicePoll,
                             [:pointer, :uint32, :pointer], :uint32

    attach_function :wgpuQueueRelease,
                    [:pointer], :void

    attach_function :wgpuQueueSubmit,
                    [:pointer, :size_t, :pointer], :void

    attach_function :wgpuQueueOnSubmittedWorkDone,
                    [:pointer, QueueWorkDoneCallbackInfo.by_value], Future.by_value

    attach_function :wgpuQueueWriteBuffer,
                    [:pointer, :pointer, :uint64, :pointer, :size_t], :void

    attach_function :wgpuQueueWriteTexture,
                    [:pointer, :pointer, :pointer, :size_t, :pointer, :pointer], :void

    attach_function :wgpuBufferRelease,
                    [:pointer], :void

    attach_function :wgpuBufferDestroy,
                    [:pointer], :void

    attach_function :wgpuBufferMapAsync,
                    [:pointer, :uint64, :size_t, :size_t, BufferMapCallbackInfo.by_value], Future.by_value

    attach_function :wgpuBufferUnmap,
                    [:pointer], :void

    attach_function :wgpuBufferGetMappedRange,
                    [:pointer, :size_t, :size_t], :pointer

    attach_function :wgpuBufferGetConstMappedRange,
                    [:pointer, :size_t, :size_t], :pointer

    attach_function :wgpuBufferGetSize,
                    [:pointer], :uint64

    attach_function :wgpuBufferGetUsage,
                    [:pointer], :uint64

    attach_function :wgpuBufferGetMapState,
                    [:pointer], BufferMapState

    attach_function :wgpuShaderModuleRelease,
                    [:pointer], :void

    attach_function :wgpuShaderModuleGetCompilationInfo,
                    [:pointer, CompilationInfoCallbackInfo.by_value], Future.by_value

    attach_function :wgpuCommandEncoderRelease,
                    [:pointer], :void

    attach_function :wgpuCommandEncoderBeginRenderPass,
                    [:pointer, RenderPassDescriptor.by_ref], :pointer

    attach_function :wgpuCommandEncoderBeginComputePass,
                    [:pointer, ComputePassDescriptor.by_ref], :pointer

    attach_function :wgpuCommandEncoderCopyBufferToBuffer,
                    [:pointer, :pointer, :uint64, :pointer, :uint64, :uint64], :void

    attach_function :wgpuCommandEncoderCopyBufferToTexture,
                    [:pointer, :pointer, :pointer, :pointer], :void

    attach_function :wgpuCommandEncoderCopyTextureToBuffer,
                    [:pointer, :pointer, :pointer, :pointer], :void

    attach_function :wgpuCommandEncoderCopyTextureToTexture,
                    [:pointer, :pointer, :pointer, :pointer], :void

    attach_function :wgpuCommandEncoderFinish,
                    [:pointer, :pointer], :pointer

    attach_function :wgpuCommandEncoderClearBuffer,
                    [:pointer, :pointer, :uint64, :uint64], :void

    attach_function :wgpuCommandEncoderWriteTimestamp,
                    [:pointer, :pointer, :uint32], :void

    attach_function :wgpuCommandEncoderPushDebugGroup,
                    [:pointer, StringView.by_value], :void

    attach_function :wgpuCommandEncoderPopDebugGroup,
                    [:pointer], :void

    attach_function :wgpuCommandEncoderInsertDebugMarker,
                    [:pointer, StringView.by_value], :void

    attach_function :wgpuCommandBufferRelease,
                    [:pointer], :void

    attach_function :wgpuRenderPassEncoderRelease,
                    [:pointer], :void

    attach_function :wgpuRenderPassEncoderEnd,
                    [:pointer], :void

    attach_function :wgpuRenderPassEncoderSetPipeline,
                    [:pointer, :pointer], :void

    attach_function :wgpuRenderPassEncoderSetBindGroup,
                    [:pointer, :uint32, :pointer, :size_t, :pointer], :void

    attach_function :wgpuRenderPassEncoderSetVertexBuffer,
                    [:pointer, :uint32, :pointer, :uint64, :uint64], :void

    attach_function :wgpuRenderPassEncoderSetIndexBuffer,
                    [:pointer, :pointer, IndexFormat, :uint64, :uint64], :void

    attach_function :wgpuRenderPassEncoderDraw,
                    [:pointer, :uint32, :uint32, :uint32, :uint32], :void

    attach_function :wgpuRenderPassEncoderDrawIndexed,
                    [:pointer, :uint32, :uint32, :uint32, :int32, :uint32], :void

    attach_function :wgpuRenderPassEncoderSetViewport,
                    [:pointer, :float, :float, :float, :float, :float, :float], :void

    attach_function :wgpuRenderPassEncoderSetScissorRect,
                    [:pointer, :uint32, :uint32, :uint32, :uint32], :void

    attach_function :wgpuRenderPassEncoderSetBlendConstant,
                    [:pointer, :pointer], :void

    attach_function :wgpuRenderPassEncoderSetStencilReference,
                    [:pointer, :uint32], :void

    attach_function :wgpuRenderPassEncoderDrawIndirect,
                    [:pointer, :pointer, :uint64], :void

    attach_function :wgpuRenderPassEncoderDrawIndexedIndirect,
                    [:pointer, :pointer, :uint64], :void

    attach_function :wgpuRenderPassEncoderExecuteBundles,
                    [:pointer, :size_t, :pointer], :void

    attach_function :wgpuRenderPassEncoderBeginOcclusionQuery,
                    [:pointer, :uint32], :void

    attach_function :wgpuRenderPassEncoderEndOcclusionQuery,
                    [:pointer], :void

    attach_function :wgpuRenderPassEncoderPushDebugGroup,
                    [:pointer, StringView.by_value], :void

    attach_function :wgpuRenderPassEncoderPopDebugGroup,
                    [:pointer], :void

    attach_function :wgpuRenderPassEncoderInsertDebugMarker,
                    [:pointer, StringView.by_value], :void

    attach_function :wgpuComputePassEncoderRelease,
                    [:pointer], :void

    attach_function :wgpuComputePassEncoderEnd,
                    [:pointer], :void

    attach_function :wgpuComputePassEncoderSetPipeline,
                    [:pointer, :pointer], :void

    attach_function :wgpuComputePassEncoderSetBindGroup,
                    [:pointer, :uint32, :pointer, :size_t, :pointer], :void

    attach_function :wgpuComputePassEncoderDispatchWorkgroups,
                    [:pointer, :uint32, :uint32, :uint32], :void

    attach_function :wgpuComputePassEncoderDispatchWorkgroupsIndirect,
                    [:pointer, :pointer, :uint64], :void

    attach_function :wgpuComputePassEncoderPushDebugGroup,
                    [:pointer, StringView.by_value], :void

    attach_function :wgpuComputePassEncoderPopDebugGroup,
                    [:pointer], :void

    attach_function :wgpuComputePassEncoderInsertDebugMarker,
                    [:pointer, StringView.by_value], :void

    attach_function :wgpuBindGroupRelease,
                    [:pointer], :void

    attach_function :wgpuBindGroupLayoutRelease,
                    [:pointer], :void

    attach_function :wgpuPipelineLayoutRelease,
                    [:pointer], :void

    attach_function :wgpuComputePipelineRelease,
                    [:pointer], :void

    attach_function :wgpuRenderPipelineRelease,
                    [:pointer], :void

    attach_function :wgpuTextureRelease,
                    [:pointer], :void

    attach_function :wgpuTextureDestroy,
                    [:pointer], :void

    attach_function :wgpuTextureCreateView,
                    [:pointer, :pointer], :pointer

    attach_function :wgpuTextureViewRelease,
                    [:pointer], :void

    attach_function :wgpuAdapterInfoFreeMembers,
                    [AdapterInfo.by_value], :void

    attach_function :wgpuSamplerRelease,
                    [:pointer], :void

    attach_function :wgpuInstanceCreateSurface,
                    [:pointer, SurfaceDescriptor.by_ref], :pointer

    attach_function :wgpuSurfaceRelease,
                    [:pointer], :void

    attach_function :wgpuSurfaceConfigure,
                    [:pointer, SurfaceConfiguration.by_ref], :void

    attach_function :wgpuSurfaceUnconfigure,
                    [:pointer], :void

    attach_function :wgpuSurfaceGetCurrentTexture,
                    [:pointer, SurfaceTexture.by_ref], :void

    attach_function :wgpuSurfacePresent,
                    [:pointer], :void

    attach_function :wgpuSurfaceGetCapabilities,
                    [:pointer, :pointer, SurfaceCapabilities.by_ref], :void

    attach_function :wgpuSurfaceCapabilitiesFreeMembers,
                    [SurfaceCapabilities.by_value], :void

    attach_function :wgpuTextureGetWidth,
                    [:pointer], :uint32

    attach_function :wgpuTextureGetHeight,
                    [:pointer], :uint32

    attach_function :wgpuTextureGetDepthOrArrayLayers,
                    [:pointer], :uint32

    attach_function :wgpuTextureGetMipLevelCount,
                    [:pointer], :uint32

    attach_function :wgpuTextureGetSampleCount,
                    [:pointer], :uint32

    attach_function :wgpuTextureGetDimension,
                    [:pointer], TextureDimension

    attach_function :wgpuTextureGetFormat,
                    [:pointer], TextureFormat

    attach_function :wgpuTextureGetUsage,
                    [:pointer], :uint64

    attach_function :wgpuDeviceCreateQuerySet,
                    [:pointer, QuerySetDescriptor.by_ref], :pointer

    attach_function :wgpuQuerySetDestroy,
                    [:pointer], :void

    attach_function :wgpuQuerySetRelease,
                    [:pointer], :void

    attach_function :wgpuQuerySetGetCount,
                    [:pointer], :uint32

    attach_function :wgpuQuerySetGetType,
                    [:pointer], QueryType

    attach_function :wgpuCommandEncoderResolveQuerySet,
                    [:pointer, :pointer, :uint32, :uint32, :pointer, :uint64], :void

    attach_function :wgpuAdapterGetFeatures,
                    [:pointer, SupportedFeatures.by_ref], :void

    attach_function :wgpuDeviceGetFeatures,
                    [:pointer, SupportedFeatures.by_ref], :void

    attach_function :wgpuDeviceGetLimits,
                    [:pointer, SupportedLimits.by_ref], :uint32

    attach_function :wgpuDevicePushErrorScope,
                    [:pointer, ErrorFilter], :void

    attach_function :wgpuDevicePopErrorScope,
                    [:pointer, PopErrorScopeCallbackInfo.by_value], Future.by_value

    attach_function :wgpuComputePipelineGetBindGroupLayout,
                    [:pointer, :uint32], :pointer

    attach_function :wgpuRenderPipelineGetBindGroupLayout,
                    [:pointer, :uint32], :pointer

    attach_function :wgpuDeviceCreateRenderBundleEncoder,
                    [:pointer, RenderBundleEncoderDescriptor.by_ref], :pointer

    attach_function :wgpuRenderBundleEncoderFinish,
                    [:pointer, :pointer], :pointer

    attach_function :wgpuRenderBundleEncoderRelease,
                    [:pointer], :void

    attach_function :wgpuRenderBundleRelease,
                    [:pointer], :void

    attach_function :wgpuRenderBundleEncoderSetPipeline,
                    [:pointer, :pointer], :void

    attach_function :wgpuRenderBundleEncoderSetBindGroup,
                    [:pointer, :uint32, :pointer, :size_t, :pointer], :void

    attach_function :wgpuRenderBundleEncoderSetVertexBuffer,
                    [:pointer, :uint32, :pointer, :uint64, :uint64], :void

    attach_function :wgpuRenderBundleEncoderSetIndexBuffer,
                    [:pointer, :pointer, IndexFormat, :uint64, :uint64], :void

    attach_function :wgpuRenderBundleEncoderDraw,
                    [:pointer, :uint32, :uint32, :uint32, :uint32], :void

    attach_function :wgpuRenderBundleEncoderDrawIndexed,
                    [:pointer, :uint32, :uint32, :uint32, :int32, :uint32], :void

    attach_function :wgpuRenderBundleEncoderDrawIndirect,
                    [:pointer, :pointer, :uint64], :void

    attach_function :wgpuRenderBundleEncoderDrawIndexedIndirect,
                    [:pointer, :pointer, :uint64], :void

    attach_function :wgpuRenderBundleEncoderPushDebugGroup,
                    [:pointer, StringView.by_value], :void

    attach_function :wgpuRenderBundleEncoderPopDebugGroup,
                    [:pointer], :void

    attach_function :wgpuRenderBundleEncoderInsertDebugMarker,
                    [:pointer, StringView.by_value], :void

    attach_optional_function :wgpuSetLogCallback,
                             [:log_callback, :pointer], :void

    attach_optional_function :wgpuSetLogLevel,
                             [LogLevel], :void
  end
end
