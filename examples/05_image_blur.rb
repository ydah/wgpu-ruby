#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../lib/wgpu"

SHADER_CODE = <<~WGSL
  @group(0) @binding(0) var<storage, read> input: array<f32>;
  @group(0) @binding(1) var<storage, read_write> output: array<f32>;
  @group(0) @binding(2) var<uniform> params: vec2<u32>;

  @compute @workgroup_size(16, 16)
  fn main(@builtin(global_invocation_id) id: vec3<u32>) {
    let width = params.x;
    let height = params.y;
    let x = id.x;
    let y = id.y;

    if (x >= width || y >= height) {
      return;
    }

    var sum: f32 = 0.0;
    var count: f32 = 0.0;

    for (var dy: i32 = -1; dy <= 1; dy = dy + 1) {
      for (var dx: i32 = -1; dx <= 1; dx = dx + 1) {
        let nx = i32(x) + dx;
        let ny = i32(y) + dy;

        if (nx >= 0 && nx < i32(width) && ny >= 0 && ny < i32(height)) {
          let idx = u32(ny) * width + u32(nx);
          sum = sum + input[idx];
          count = count + 1.0;
        }
      }
    }

    let out_idx = y * width + x;
    output[out_idx] = sum / count;
  }
WGSL

instance = WGPU::Instance.new
adapter = instance.request_adapter
device = adapter.request_device
queue = device.queue

puts "=== GPU Image Blur Example (3x3 Box Filter) ==="

width, height = 8, 8
image = Array.new(width * height) { |i| ((i % width) + (i / width)).to_f }

puts "\nInput image (#{width}x#{height}):"
height.times do |y|
  row = width.times.map { |x| image[y * width + x].round(1).to_s.rjust(4) }
  puts "  #{row.join(' ')}"
end

input_buffer = device.create_buffer_with_data(
  data: image,
  usage: [:storage]
)

output_buffer = device.create_buffer(
  size: width * height * 4,
  usage: [:storage, :copy_src],
  mapped_at_creation: false
)

params_buffer = device.create_buffer_with_data(
  data: [width, height].pack("L<L<"),
  usage: [:uniform]
)

shader = device.create_shader_module(code: SHADER_CODE)

bind_group_layout = device.create_bind_group_layout(
  entries: [
    { binding: 0, visibility: :compute, buffer: { type: :read_only_storage } },
    { binding: 1, visibility: :compute, buffer: { type: :storage } },
    { binding: 2, visibility: :compute, buffer: { type: :uniform } }
  ]
)

bind_group = device.create_bind_group(
  layout: bind_group_layout,
  entries: [
    { binding: 0, buffer: input_buffer, offset: 0, size: input_buffer.size },
    { binding: 1, buffer: output_buffer, offset: 0, size: output_buffer.size },
    { binding: 2, buffer: params_buffer, offset: 0, size: params_buffer.size }
  ]
)

pipeline_layout = device.create_pipeline_layout(bind_group_layouts: [bind_group_layout])
pipeline = device.create_compute_pipeline(
  layout: pipeline_layout,
  compute: { module: shader, entry_point: "main" }
)

encoder = device.create_command_encoder
pass = encoder.begin_compute_pass
pass.set_pipeline(pipeline)
pass.set_bind_group(0, bind_group)
pass.dispatch_workgroups((width + 15) / 16, (height + 15) / 16)
pass.end_pass
queue.submit([encoder.finish])

result = queue.read_buffer(output_buffer, device: device)
blurred = result.unpack("f*")

puts "\nBlurred image (3x3 box filter):"
height.times do |y|
  row = width.times.map { |x| blurred[y * width + x].round(1).to_s.rjust(4) }
  puts "  #{row.join(' ')}"
end

[input_buffer, output_buffer, params_buffer, shader, bind_group_layout, bind_group, pipeline_layout, pipeline, encoder].each(&:release)
device.release
adapter.release
instance.release
puts "\nDone!"
