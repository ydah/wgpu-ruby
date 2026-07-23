# frozen_string_literal: true

require_relative "wgpu/version"
require_relative "wgpu/error"
require_relative "wgpu/native/loader"
require_relative "wgpu/native/enum_helper"
require_relative "wgpu/native/abi_verifier"
require_relative "wgpu/descriptor_helpers"
require_relative "wgpu/native_resource"
require_relative "wgpu/async_task"
require_relative "wgpu/core/async_waiter"

require_relative "wgpu/resources/buffer"
require_relative "wgpu/resources/texture"
require_relative "wgpu/resources/texture_view"
require_relative "wgpu/resources/sampler"
require_relative "wgpu/resources/query_set"

require_relative "wgpu/pipeline/shader_module"
require_relative "wgpu/pipeline/bind_group_layout"
require_relative "wgpu/pipeline/bind_group"
require_relative "wgpu/pipeline/pipeline_layout"
require_relative "wgpu/pipeline/compute_pipeline"
require_relative "wgpu/pipeline/render_pipeline"

require_relative "wgpu/commands/command_buffer"
require_relative "wgpu/commands/compute_pass"
require_relative "wgpu/commands/render_pass"
require_relative "wgpu/commands/render_bundle"
require_relative "wgpu/commands/render_bundle_encoder"
require_relative "wgpu/commands/command_encoder"

require_relative "wgpu/core/queue"
require_relative "wgpu/core/device"
require_relative "wgpu/core/adapter"
require_relative "wgpu/core/instance"
require_relative "wgpu/core/surface"
require_relative "wgpu/core/canvas_context"

module WGPU
  [
    Instance,
    Adapter,
    Device,
    Queue,
    Surface,
    CanvasContext,
    Buffer,
    Texture,
    TextureView,
    Sampler,
    QuerySet,
    ShaderModule,
    BindGroupLayout,
    BindGroup,
    PipelineLayout,
    ComputePipeline,
    RenderPipeline,
    CommandEncoder,
    CommandBuffer,
    ComputePass,
    RenderPass,
    RenderBundleEncoder,
    RenderBundle
  ].each { |resource_class| resource_class.include(NativeResource) }
end
