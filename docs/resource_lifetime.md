# Resource lifetime

wgpu-ruby follows wgpu-native's explicit reference-counted handle model.
Callers own every wrapper returned to them and must call `release` when it is no
longer needed. The library does not automatically release native handles from
Ruby finalizers.

## `release` and `destroy`

- `release` gives up the wrapper's native reference. It sets the stored handle
  to `FFI::Pointer::NULL`; calling `release` again is harmless.
- `destroy` immediately invalidates the underlying GPU resource contents but
  does not give up the wrapper's reference. Call `release` after `destroy`.
- Calling another public native operation after `release` raises
  `WGPU::ResourceError` before FFI is entered. `handle`, `released?`, `label`,
  `inspect`, and repeated `release` remain available.
- Every native wrapper supports `use { |resource| ... }`. It returns the block
  result and releases the wrapper in `ensure`, including when the block raises.
  This is Ruby convenience API rather than a WebGPU operation.

For short-lived resources:

```ruby
bytes = device.create_buffer(
  size: 256,
  usage: %i[map_read copy_dst]
).use do |buffer|
  # Work with buffer; it is released on every exit path.
end
```

## Wrapper matrix

The table covers all 23 native wrapper classes. `BufferMappedRange`,
`AsyncTask`, and `Window::SDLWindow` are not independent wgpu-native
reference-counted handles.

| Wrapper | `release` | `destroy` | Ownership note |
|---|:---:|:---:|---|
| `Instance` | ✅ | — | Release after all adapters/surfaces derived from it. |
| `Adapter` | ✅ | — | Returned by instance discovery/request. |
| `Device` | ✅ | ✅ | `release` also releases the cached queue wrapper first. |
| `Queue` | ✅ | — | Normally owned through `Device#queue`; device release cascades to it. |
| `Surface` | ✅ | — | Release after unconfiguring and after current texture work completes. |
| `CanvasContext` | ✅ | — | Releases its internally created surface. |
| `Buffer` | ✅ | ✅ | Destroy contents when early reclamation is desired, then release. |
| `Texture` | ✅ | ✅ | Texture views should be released before their texture. |
| `TextureView` | ✅ | — | `Texture#from_handle`/view wrappers are caller-owned. |
| `Sampler` | ✅ | — | |
| `QuerySet` | ✅ | ✅ | Destroy query storage, then release the reference. |
| `ShaderModule` | ✅ | — | |
| `BindGroupLayout` | ✅ | — | Layouts returned by `get_bind_group_layout` are caller-owned. |
| `BindGroup` | ✅ | — | |
| `PipelineLayout` | ✅ | — | |
| `ComputePipeline` | ✅ | — | |
| `RenderPipeline` | ✅ | — | |
| `CommandEncoder` | ✅ | — | Finish before release. |
| `CommandBuffer` | ✅ | — | Release after submission is no longer needed. |
| `ComputePass` | ✅ | — | End the pass before finishing its encoder. |
| `RenderPass` | ✅ | — | End the pass before finishing its encoder. |
| `RenderBundleEncoder` | ✅ | — | Finish before release. |
| `RenderBundle` | ✅ | — | |

## Recommended release order

Release in the reverse order of creation:

1. End active compute/render passes.
2. Finish encoders and submit command buffers.
3. Release pass encoders, command buffers, and command encoders.
4. Release bind groups, pipelines/layouts, shader modules, samplers, texture
   views, buffers, textures, and query sets.
5. Unconfigure and release surfaces/canvas contexts.
6. Release the device (which releases its queue), then adapter and instance.

Explicitly synchronize work when the application needs resources to remain
alive until completion. A successful `Queue#submit` does not itself release the
submitted command buffer or its referenced Ruby wrappers.

## Internal staging resources

`Queue#read_buffer` and `Queue#read_texture` create a temporary staging buffer,
submit a copy, map and read it, then unmap and release it. In the baseline
implementation cleanup runs from `ensure`, including exceptional paths.
Applications should not attempt to retain or release this internal buffer.

## Leak diagnostics

Set `WGPU_DEBUG_LEAKS=1` before requiring the gem, or set
`WGPU.debug_leaks = true` before creating resources, to enable warnings.
Unreleased resources are reported with their wrapper class and label during GC
or process exit. The detector never releases a native handle; it is diagnostic
only and is disabled by default.
