# Getting started: compute

Compute workloads need Ruby 3.2+, the `wgpu` gem, and a supported GPU driver.
They do not need SDL3.

```ruby
require "wgpu"

instance = WGPU::Instance.new
adapter = instance.request_adapter(timeout: 10)
device = adapter.request_device(timeout: 10)

shader = device.create_shader_module(
  code: <<~WGSL,
    @group(0) @binding(0) var<storage, read_write> values: array<u32>;

    @compute @workgroup_size(4)
    fn main(@builtin(global_invocation_id) id: vec3<u32>) {
      values[id.x] *= 2u;
    }
  WGSL
)

buffer = device.create_buffer_with_data(
  data: [1, 2, 3, 4],
  type: :u32,
  usage: %i[storage copy_src copy_dst]
)

pipeline = device.create_compute_pipeline(
  layout: :auto,
  compute: { module: shader }
)
layout = pipeline.get_bind_group_layout(0)
group = device.create_bind_group(
  layout: layout,
  entries: [{ binding: 0, buffer: buffer }]
)

encoder = device.create_command_encoder
encoder.begin_compute_pass do |pass|
  pass.set_pipeline(pipeline)
  pass.set_bind_group(0, group)
  pass.dispatch_workgroups(1)
end
command_buffer = encoder.finish
device.queue.submit(command_buffer)

bytes = device.queue.read_buffer(buffer)
puts WGPU::DataTypes.unpack(bytes, type: :u32).inspect

[command_buffer, encoder, group, layout, pipeline, buffer, shader].each(&:release)
device.release
adapter.release
instance.release
```

The full executable version is
[`examples/02_compute_basic.rb`](../examples/02_compute_basic.rb). For
production code, put resource release in `ensure` blocks and register
`Device#on_uncaptured_error` during startup.
