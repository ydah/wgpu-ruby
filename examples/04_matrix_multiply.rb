#!/usr/bin/env ruby
# frozen_string_literal: true

# Purpose: multiply two matrices with a compute shader.
# APIs: storage/uniform buffers, compute pipeline/pass, workgroup dispatch, readback.
# Expected: the GPU result matches the CPU matrix multiplication result.

require_relative "../lib/wgpu"

SHADER_CODE = <<~WGSL
  struct Matrix {
    size: vec2<u32>,
    data: array<f32>,
  }

  @group(0) @binding(0) var<storage, read> a: Matrix;
  @group(0) @binding(1) var<storage, read> b: Matrix;
  @group(0) @binding(2) var<storage, read_write> c: Matrix;

  @compute @workgroup_size(8, 8)
  fn main(@builtin(global_invocation_id) id: vec3<u32>) {
    let row = id.x;
    let col = id.y;

    if (row >= a.size.x || col >= b.size.y) {
      return;
    }

    var sum: f32 = 0.0;
    for (var k: u32 = 0u; k < a.size.y; k = k + 1u) {
      let a_idx = row * a.size.y + k;
      let b_idx = k * b.size.y + col;
      sum = sum + a.data[a_idx] * b.data[b_idx];
    }

    let c_idx = row * b.size.y + col;
    c.data[c_idx] = sum;
  }
WGSL

def create_matrix_buffer(device, rows, cols, data)
  buffer_data = [rows, cols].pack("L<L<") + data.pack("f*")
  device.create_buffer_with_data(
    data: buffer_data,
    usage: [:storage, :copy_src]
  )
end

def create_output_buffer(device, rows, cols)
  size = 8 + (rows * cols * 4)
  buffer = device.create_buffer(
    size: size,
    usage: [:storage, :copy_src, :copy_dst],
    mapped_at_creation: true
  )
  buffer.mapped_range.write_bytes([rows, cols].pack("L<L<") + ("\x00" * (rows * cols * 4)))
  buffer.unmap
  buffer
end

instance = WGPU::Instance.new
adapter = instance.request_adapter
device = adapter.request_device
queue = device.queue

puts "=== GPU Matrix Multiplication Example ==="

m, k, n = 4, 4, 4
a_data = (1..(m*k)).map(&:to_f)
b_data = (1..(k*n)).map(&:to_f)

puts "\nMatrix A (#{m}x#{k}):"
m.times { |i| puts "  #{a_data[i*k, k].inspect}" }

puts "\nMatrix B (#{k}x#{n}):"
k.times { |i| puts "  #{b_data[i*n, n].inspect}" }

buffer_a = create_matrix_buffer(device, m, k, a_data)
buffer_b = create_matrix_buffer(device, k, n, b_data)
buffer_c = create_output_buffer(device, m, n)

shader = device.create_shader_module(code: SHADER_CODE)

bind_group_layout = device.create_bind_group_layout(
  entries: [
    { binding: 0, visibility: :compute, buffer: { type: :read_only_storage } },
    { binding: 1, visibility: :compute, buffer: { type: :read_only_storage } },
    { binding: 2, visibility: :compute, buffer: { type: :storage } }
  ]
)

bind_group = device.create_bind_group(
  layout: bind_group_layout,
  entries: [
    { binding: 0, buffer: buffer_a, offset: 0, size: buffer_a.size },
    { binding: 1, buffer: buffer_b, offset: 0, size: buffer_b.size },
    { binding: 2, buffer: buffer_c, offset: 0, size: buffer_c.size }
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
pass.dispatch_workgroups((m + 7) / 8, (n + 7) / 8)
pass.end_pass
queue.submit([encoder.finish])

result = queue.read_buffer(buffer_c, offset: 8, size: m * n * 4, device: device)
c_data = result.unpack("f*")

puts "\nResult C (#{m}x#{n}) - GPU:"
m.times { |i| puts "  #{c_data[i*n, n].map { |x| x.round(1) }.inspect}" }

expected = Array.new(m * n, 0.0)
m.times do |i|
  n.times do |j|
    k.times do |kk|
      expected[(i * n) + j] += a_data[(i * k) + kk] * b_data[(kk * n) + j]
    end
  end
end

puts "\nExpected C (#{m}x#{n}) - CPU:"
m.times { |i| puts "  #{expected[i*n, n].map { |x| x.round(1) }.inspect}" }

match = c_data.zip(expected).all? { |a, b| (a - b).abs < 0.001 }
puts "\nVerification: #{match ? 'PASSED' : 'FAILED'}"

[buffer_a, buffer_b, buffer_c, shader, bind_group_layout, bind_group, pipeline_layout, pipeline, encoder].each(&:release)
device.release
adapter.release
instance.release
puts "Done!"
