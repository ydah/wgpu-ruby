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
