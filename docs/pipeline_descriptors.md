# Pipeline descriptors

`WGPU::ComputePipeline` and `WGPU::RenderPipeline` accept Ruby Hashes that mirror
WebGPU pipeline descriptors. Passing `layout: :auto`, `"auto"`, or `nil` requests
automatic layout inference. A layout object continues to select an explicit
pipeline layout.

## Default render state

The wrapper applies the following WebGPU defaults when a field is omitted:

| State | Field | Default |
|---|---|---|
| Vertex | `entry_point` | `"main"` |
| Vertex buffer | `step_mode` | `:vertex` |
| Primitive | `topology` | `:triangle_list` |
| Primitive | `strip_index_format` | `:undefined` |
| Primitive | `front_face` | `:ccw` |
| Primitive | `cull_mode` | `:none` |
| Primitive | `unclipped_depth` | `false` |
| Multisample | `count` | `1` |
| Multisample | `mask` | `0xFFFFFFFF` |
| Multisample | `alpha_to_coverage_enabled` | `false` |
| Depth/stencil | `depth_compare` | `:always` |
| Stencil face | operations | `:keep` |
| Color target | `write_mask` | `:all` |
| Blend component | `operation` | `:add` |
| Blend component | `src_factor` | `:one` |
| Blend component | `dst_factor` | `:zero` |

`vertex[:module]`, each vertex attribute's `format`, `offset`, and
`shader_location`, and each color target's `format` are required. A
depth/stencil state requires `format`. Unknown descriptor keys produce a warning
so misspellings are visible while preserving v1.x compatibility.

Both vertex/fragment and compute stages accept `constants:`, a Hash mapping WGSL
override names to numeric values. The descriptor keeps all FFI strings and
arrays alive until native pipeline creation completes.
