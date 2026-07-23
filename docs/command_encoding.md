# Command encoding

Compute and render passes support both the original explicit form and an
ensure-safe block form:

```ruby
encoder.begin_compute_pass do |pass|
  pass.set_pipeline(pipeline)
  pass.dispatch_workgroups(4)
end

encoder.begin_render_pass(color_attachments: attachments) do |pass|
  pass.set_pipeline(pipeline)
  pass.draw(3)
end
```

The block form always ends and releases the pass, including when the block
raises, and returns the block's value. The explicit form remains compatible:
call `end_pass` (or `end`) and `release` yourself.

Only one pass may be active on a command encoder. `CommandEncoder#finish`
raises `WGPU::CommandError` while a pass is still active instead of handing
invalid state to wgpu-native. Calling `end_pass` more than once is harmless.

## Queries and debug markers

Pass descriptors accept `timestamp_writes:` with a query set and beginning/end
indices. Render passes additionally accept `occlusion_query_set:` and expose
`begin_occlusion_query` / `end_occlusion_query`. Copy completed query values
into a buffer with `CommandEncoder#resolve_query_set`; timestamp queries
require the adapter's `:timestamp_query` feature and a device requested with
that feature.

[`examples/15_timestamp_query.rb`](../examples/15_timestamp_query.rb) shows the
complete feature-gated timestamp flow, including query resolution and typed
`u64` readback.

Command encoders, compute/render passes, and render bundle encoders expose
`push_debug_group`, `pop_debug_group`, and `insert_debug_marker`. Labels are
forwarded directly to wgpu-native for capture/debugging tools:

```ruby
encoder.push_debug_group("upload and dispatch")
encoder.insert_debug_marker("resources ready")
encoder.pop_debug_group
```

Debug groups must be balanced before the encoder or pass is finished.
