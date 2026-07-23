#!/usr/bin/env ruby
# frozen_string_literal: true

# Purpose: reduce a large f32 array through repeated compute dispatches.
# APIs: Queue#write_buffer, compute pipeline/pass, repeated submit and readback.
# Expected: the GPU sum matches Ruby's expected sum.

require_relative "../lib/wgpu"

SHADER_CODE = <<~WGSL
  @group(0) @binding(0) var<storage, read_write> data: array<f32>;
  @group(0) @binding(1) var<uniform> stride: u32;

  @compute @workgroup_size(256)
  fn main(@builtin(global_invocation_id) id: vec3<u32>) {
    let i = id.x;
    let partner = i + stride;

    if (i % (stride * 2u) == 0u && partner < arrayLength(&data)) {
      data[i] = data[i] + data[partner];
    }
  }
WGSL

instance = WGPU::Instance.new
adapter = instance.request_adapter
device = adapter.request_device
queue = device.queue

puts "=== GPU Parallel Reduction (Sum) Example ==="

n = 1024
input_data = (1..n).map(&:to_f)
expected_sum = input_data.sum

puts "\nInput: #{n} numbers (1 to #{n})"
puts "Expected sum: #{expected_sum.to_i}"

data_buffer = device.create_buffer_with_data(
  data: input_data,
  usage: [:storage, :copy_src, :copy_dst]
)

stride_buffer = device.create_buffer(
  size: 4,
  usage: [:uniform, :copy_dst]
)

shader = device.create_shader_module(code: SHADER_CODE)

bind_group_layout = device.create_bind_group_layout(
  entries: [
    { binding: 0, visibility: :compute, buffer: { type: :storage } },
    { binding: 1, visibility: :compute, buffer: { type: :uniform } }
  ]
)

bind_group = device.create_bind_group(
  layout: bind_group_layout,
  entries: [
    { binding: 0, buffer: data_buffer, offset: 0, size: data_buffer.size },
    { binding: 1, buffer: stride_buffer, offset: 0, size: stride_buffer.size }
  ]
)

pipeline_layout = device.create_pipeline_layout(bind_group_layouts: [bind_group_layout])
pipeline = device.create_compute_pipeline(
  layout: pipeline_layout,
  compute: { module: shader, entry_point: "main" }
)

stride = 1
iterations = 0
while stride < n
  queue.write_buffer(stride_buffer, 0, [stride], type: :u32)

  encoder = device.create_command_encoder
  pass = encoder.begin_compute_pass
  pass.set_pipeline(pipeline)
  pass.set_bind_group(0, bind_group)
  pass.dispatch_workgroups((n + 255) / 256)
  pass.end_pass
  queue.submit([encoder.finish])
  encoder.release

  stride *= 2
  iterations += 1
end

result = queue.read_buffer(data_buffer, size: 4, device: device)
gpu_sum = result.unpack1("f")

puts "GPU sum: #{gpu_sum.to_i}"
puts "Iterations: #{iterations}"
puts "Verification: #{(gpu_sum - expected_sum).abs < 0.001 ? 'PASSED' : 'FAILED'}"

[data_buffer, stride_buffer, shader, bind_group_layout, bind_group, pipeline_layout, pipeline].each(&:release)
device.release
adapter.release
instance.release
puts "Done!"
