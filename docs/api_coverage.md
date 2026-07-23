# WebGPU API coverage

This page records the public Ruby API implemented by wgpu-ruby 1.1 and its
relationship to the WebGPU object model. It is a baseline, not a claim that
every WebGPU feature is implemented.

The WebGPU names below follow the
[WebGPU Editor's Draft](https://gpuweb.github.io/gpuweb/). Browser-only APIs
such as DOM canvas discovery and external image import are intentionally
called out instead of being hidden by a general "complete" claim.

Legend:

- ✅: a public Ruby wrapper exists for the interface's core operations
- ◐: some operations or the returned data shape are implemented
- ❌: no public wrapper exists
- N/A: browser integration that does not map directly to a native Ruby binding

## Object and supporting-interface coverage

| WebGPU interface | Ruby API | Status | Notes |
|---|---|:---:|---|
| `GPU` | `WGPU::Instance` | ◐ | Native entry point; adapter requests and event processing are exposed. Browser canvas-format and WGSL-language-feature queries are not. |
| `GPUAdapter` | `WGPU::Adapter` | ✅ | Adapter info, features, limits, and device requests are exposed. |
| `GPUAdapterInfo` | `Hash` from `Adapter#info` | ◐ | Returned as a Ruby hash rather than a value object. |
| `GPUBindGroup` | `WGPU::BindGroup` | ✅ | |
| `GPUBindGroupLayout` | `WGPU::BindGroupLayout` | ✅ | |
| `GPUBuffer` | `WGPU::Buffer` | ✅ | Mapping, destruction, and Ruby data helpers are included. |
| `GPUCanvasContext` | `WGPU::CanvasContext` | ◐ | Native-window presentation wrapper; no DOM `canvas` attribute. |
| `GPUCommandBuffer` | `WGPU::CommandBuffer` | ✅ | |
| `GPUCommandEncoder` | `WGPU::CommandEncoder` | ✅ | Buffer/texture copies, query resolution, timestamps, and debug markers are exposed. |
| `GPUCompilationInfo` | `ShaderModule#get_compilation_info` + `CompilationMessage` | ✅ | Typed diagnostics retain the v1.x outer Hash. |
| `GPUCompilationMessage` | `Hash` entries | ◐ | Message, type, line, column, offset, and length are returned. |
| `GPUComputePassEncoder` | `WGPU::ComputePass` | ✅ | |
| `GPUComputePipeline` | `WGPU::ComputePipeline` | ✅ | Auto layout and override constants are accepted. |
| `GPUDevice` | `WGPU::Device` | ◐ | Resource creation, error scopes, polling, features, and limits are exposed; device-lost and uncaptured-error subscriptions are not. |
| `GPUDeviceLostInfo` | — | ❌ | |
| `GPUError` | error hashes and `WGPU::Error` subclasses | ◐ | There is no common `GPUError` value object yet. |
| `GPUExternalTexture` | — | ❌ | Browser video/external-texture import is not exposed. |
| `GPUInternalError` | — | ❌ | |
| `GPUOutOfMemoryError` | — | ❌ | |
| `GPUPipelineError` | `WGPU::PipelineError` | ◐ | Ruby exception exists; native pipeline error data is not a value object. |
| `GPUPipelineLayout` | `WGPU::PipelineLayout` | ✅ | |
| `GPUQuerySet` | `WGPU::QuerySet` | ✅ | |
| `GPUQueue` | `WGPU::Queue` | ◐ | Submission, writes, work-done notification, and readback helpers are exposed; browser `copyExternalImageToTexture` is not. |
| `GPURenderBundle` | `WGPU::RenderBundle` | ✅ | |
| `GPURenderBundleEncoder` | `WGPU::RenderBundleEncoder` | ✅ | |
| `GPURenderPassEncoder` | `WGPU::RenderPass` | ✅ | |
| `GPURenderPipeline` | `WGPU::RenderPipeline` | ✅ | Auto layout and override constants are accepted. |
| `GPUSampler` | `WGPU::Sampler` | ✅ | |
| `GPUShaderModule` | `WGPU::ShaderModule` | ✅ | WGSL and wgpu-native SPIR-V/GLSL extensions are supported. |
| `GPUSupportedFeatures` | `Array<Symbol>` | ◐ | Represented as a Ruby array. |
| `GPUSupportedLimits` | `Hash` | ◐ | Represented as a Ruby hash. |
| `GPUTexture` | `WGPU::Texture` | ✅ | |
| `GPUTextureView` | `WGPU::TextureView` | ✅ | |
| `GPUUncapturedErrorEvent` | — | ❌ | |
| `GPUValidationError` | class-specific Ruby exceptions | ◐ | Validation errors are translated during resource creation. |
| `WGSLLanguageFeatures` | — | ❌ | |
| `GPUObjectBase` | `#handle`, labels on descriptors | ◐ | Common released-state behavior is not yet centralized. |
| `GPUPipelineBase` | `#get_bind_group_layout` | ✅ | Implemented by compute and render pipelines. |
| `GPUCommandsMixin` | `WGPU::CommandEncoder` | ✅ | |
| `GPUDebugCommandsMixin` | encoder/pass debug methods | ✅ | |
| `GPUBindingCommandsMixin` | pass/bundle binding methods | ✅ | |
| `GPURenderCommandsMixin` | render pass/bundle draw methods | ✅ | |
| `NavigatorGPU` | — | N/A | Browser-only discovery API. |

Descriptor dictionaries are represented as Ruby keyword arguments and nested
hashes, then converted to the matching `WGPU*Descriptor` FFI structs. The
implemented object APIs cover buffer, texture/view, sampler, bind group/layout,
pipeline layout, shader module, compute/render pipeline, command/pass/bundle,
query set, surface, and device/adapter/instance descriptors. Browser-only
descriptors (`GPUExternalTextureDescriptor`, external image copy descriptors,
and DOM canvas ownership) are not implemented.

## Public Ruby API

Constructors are omitted where objects are normally returned by another
wrapper. `handle` readers are listed once here as a common escape hatch for
native interoperation.

| Ruby class | Public class methods | Public instance methods |
|---|---|---|
| `WGPU::Instance` | — | `request_adapter`, `request_adapter_async`, `enumerate_adapters`, `enumerate_adapters_async`, `process_events`, `get_canvas_context`, `release`, `handle` |
| `WGPU::Adapter` | `request`, `from_handle` | `request_device`, `request_device_async`, `info`, `name`, `vendor`, `adapter_type`, `backend_type`, `features`, `has_feature?`, `limits`, `summary`, `release`, `handle`, `instance` |
| `WGPU::Device` | `request` | `queue`, `adapter`, `adapter_info`, `features`, `has_feature?`, `limits`, all `create_*` methods, `push_error_scope`, `pop_error_scope`, `pop_error_scope_async`, `with_error_scope`, `poll`, `destroy`, `release`, `handle` |
| `WGPU::Queue` | — | `submit`, `write_buffer`, `write_texture`, `read_buffer`, `read_texture`, `on_submitted_work_done`, `on_submitted_work_done_async`, `release`, `handle` |
| `WGPU::Surface` | `from_metal_layer`, `from_windows_hwnd`, `from_xlib_window`, `from_wayland_surface` | `configure`, `unconfigure`, `current_texture`, `get_current_texture`, `present`, `get_configuration`, `get_preferred_format`, `capabilities`, `release`, `handle` |
| `WGPU::CanvasContext` | — | `configure`, `unconfigure`, `get_current_texture`, `present`, `get_configuration`, `get_preferred_format`, `set_physical_size`, `physical_size`, `release` |
| `WGPU::Buffer` | — | `write`, `mapped_range`, `get_mapped_range`, `unmap`, `map_sync`, `map_async`, `read_mapped_data`, `read_mapped`, `write_mapped`, `read_mapped_floats`, `map_state`, `size`, `usage`, `destroy`, `release`, `handle` |
| `WGPU::BufferMappedRange` | — | `read_bytes`, `write_bytes`, `read_floats`, `write_floats` |
| `WGPU::Texture` | `from_handle` | `create_view`, `width`, `height`, `depth_or_array_layers`, `size`, `mip_level_count`, `sample_count`, `dimension`, `format`, `usage`, `destroy`, `release`, `handle` |
| `WGPU::TextureView` | `from_handle` | `texture`, `size`, `release`, `handle` |
| `WGPU::Sampler` | — | `release`, `handle` |
| `WGPU::QuerySet` | — | `count`, `type`, `destroy`, `release`, `handle` |
| `WGPU::ShaderModule` | — | `get_compilation_info`, `get_compilation_info_async`, `release`, `handle` |
| `WGPU::BindGroupLayout` | `from_handle` | `release`, `handle` |
| `WGPU::BindGroup` | — | `release`, `handle` |
| `WGPU::PipelineLayout` | — | `release`, `handle` |
| `WGPU::ComputePipeline` | — | `get_bind_group_layout`, `release`, `handle` |
| `WGPU::RenderPipeline` | — | `get_bind_group_layout`, `release`, `handle` |
| `WGPU::CommandEncoder` | — | `begin_compute_pass`, `begin_render_pass`, copy/clear/query/debug methods, `finish`, `release`, `handle` |
| `WGPU::CommandBuffer` | — | `release`, `handle` |
| `WGPU::ComputePass` | — | pipeline/bind-group setup, dispatch/debug methods, `end_pass`, `end`, `release`, `handle` |
| `WGPU::RenderPass` | — | pipeline/bind-group/buffer setup, draw/state/query/debug methods, `end_pass`, `end`, `release`, `handle` |
| `WGPU::RenderBundleEncoder` | — | pipeline/bind-group/buffer setup, draw/debug methods, `finish`, `release`, `handle` |
| `WGPU::RenderBundle` | — | `release`, `handle` |
| `WGPU::AsyncTask` | — | `wait`, `value`, `then`, `complete?`, `pending?`, `error` |
| `WGPU::Window::SDLWindow` | — | `create_surface`, event/key helpers, `drawable_size`, `close` |

## Examples as executable specifications

| Example | Purpose | Principal wgpu-ruby APIs exercised |
|---|---|---|
| `01_adapter_info.rb` | Adapter discovery and reporting | `Instance#enumerate_adapters`, `#request_adapter`, adapter info/features/limits |
| `02_compute_basic.rb` | Minimal storage-buffer compute | buffer mapping, bind groups/layouts, compute pipeline/pass, submit, readback |
| `03_buffer_operations.rb` | Buffer write, copy, map, and read | `create_buffer_with_data`, `Queue#write_buffer`, buffer copy, `map_sync` |
| `04_matrix_multiply.rb` | Multi-buffer compute | typed byte upload, storage/uniform bindings, workgroup dispatch, readback |
| `05_image_blur.rb` | 2D compute workload | multiple storage buffers, 2D dispatch, readback |
| `06_parallel_reduction.rb` | Iterative compute reduction | repeated dispatch/submission, `Queue#write_buffer`, readback |
| `07_triangle.rb` | Basic surface rendering | SDL surface setup, render pipeline/pass, draw, present |
| `08_colored_quad.rb` | Indexed vertex rendering | vertex/index buffers, render pipeline/pass, indexed draw |
| `09_clear_color.rb` | Per-frame clear and presentation | current texture/view, render pass clear, submit, present |
| `10_textured_quad.rb` | Texture sampling | texture upload/view, sampler, texture bind group, draw |
| `11_rotating_cube.rb` | Depth-tested 3D rendering | vertex/index/uniform/depth resources, pipeline, per-frame uniform write, draw |

When a public API changes, the corresponding example is part of the acceptance
test surface. Compute and future headless examples are suitable for automated
GPU CI; SDL window examples remain manual integration checks.
