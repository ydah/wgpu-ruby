# Bind groups and pipeline layouts

Each bind group layout entry requires `binding:`, `visibility:`, and exactly one
resource variant:

| Variant | Keys | Defaults |
|---|---|---|
| `buffer:` | `type`, `has_dynamic_offset`, `min_binding_size` | `:storage`, `false`, `0` |
| `sampler:` | `type` | `:filtering` |
| `texture:` | `sample_type`, `view_dimension`, `multisampled` | `:float`, `:d2`, `false` |
| `storage_texture:` | `format` (required), `access`, `view_dimension` | `:write_only`, `:d2` |

`visibility:` accepts one shader-stage Symbol, an integer bitmask, or an Array
such as `%i[vertex fragment]`. Unknown keys warn; missing required keys and
conflicting resource variants raise `ArgumentError` before FFI.

A bind group entry requires `binding:` and exactly one of `buffer:`,
`sampler:`, or `texture_view:`. Buffer entries may also include `offset:` and
`size:`.

Compute and render pipelines accept `layout: :auto` (also `"auto"` or `nil`).
Call `pipeline.get_bind_group_layout(index)` to obtain an inferred layout.
That returned wrapper owns a native reference; the caller must release it.
`examples/02_compute_basic.rb` demonstrates this path. Explicit
`PipelineLayout` objects remain fully supported.
