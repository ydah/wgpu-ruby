#!/usr/bin/env ruby
# frozen_string_literal: true

# Purpose: double an f32 storage buffer with a compute shader.
# APIs: buffers, auto pipeline layout, bind groups, compute pass, queue readback.
# Expected: output values are twice the input values and the script prints SUCCESS.

require_relative "../lib/wgpu"

SHADER_CODE = <<~WGSL
  @group(0) @binding(0) var<storage, read_write> data: array<f32>;

  @compute @workgroup_size(64)
  fn main(@builtin(global_invocation_id) id: vec3<u32>) {
    let i = id.x;
    data[i] = data[i] * 2.0;
  }
WGSL

instance = WGPU::Instance.new
adapter = instance.request_adapter
device = adapter.request_device
queue = device.queue

puts "=== Basic Compute Shader Example ==="
puts "Doubles each element in an array using GPU"

input_data = (0...256).map(&:to_f)
puts "\nInput (first 10): #{input_data[0, 10].inspect}"

buffer = device.create_buffer(
  label: "data buffer",
  size: input_data.size * 4,
  usage: [:storage, :copy_src, :copy_dst],
  mapped_at_creation: true
)
buffer.mapped_range.write_floats(input_data)
buffer.unmap

shader = device.create_shader_module(label: "compute shader", code: SHADER_CODE)

pipeline = device.create_compute_pipeline(
  layout: :auto,
  compute: { module: shader, entry_point: "main" }
)
bind_group_layout = pipeline.get_bind_group_layout(0)

bind_group = device.create_bind_group(
  layout: bind_group_layout,
  entries: [{
    binding: 0,
    buffer: buffer,
    offset: 0,
    size: buffer.size
  }]
)

encoder = device.create_command_encoder
pass = encoder.begin_compute_pass
pass.set_pipeline(pipeline)
pass.set_bind_group(0, bind_group)
pass.dispatch_workgroups(input_data.size / 64)
pass.end_pass
command_buffer = encoder.finish

queue.submit([command_buffer])

result = queue.read_buffer(buffer, device: device)
output_data = result.unpack("f*")

puts "Output (first 10): #{output_data[0, 10].inspect}"
puts "\nVerification: #{output_data == input_data.map { |x| x * 2.0 } ? 'PASSED' : 'FAILED'}"

[buffer, shader, bind_group_layout, bind_group, pipeline, encoder].each(&:release)
device.release
adapter.release
instance.release
puts "Done!"
