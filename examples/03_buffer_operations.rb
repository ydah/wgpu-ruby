#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../lib/wgpu"

instance = WGPU::Instance.new
adapter = instance.request_adapter
device = adapter.request_device
queue = device.queue

puts "=== Buffer Operations Example ==="

puts "\n--- 1. Create buffer with initial data ---"
data = [1.0, 2.0, 3.0, 4.0, 5.0]
buffer = device.create_buffer_with_data(
  label: "initial data buffer",
  data: data,
  usage: [:storage, :copy_src, :copy_dst]
)
puts "Created buffer with #{data.inspect}"
puts "Buffer size: #{buffer.size} bytes"
puts "Map state: #{buffer.map_state}"

puts "\n--- 2. Write to buffer via queue ---"
new_data = [10.0, 20.0, 30.0, 40.0, 50.0]
queue.write_buffer(buffer, 0, new_data)
puts "Wrote #{new_data.inspect} to buffer"

puts "\n--- 3. Read buffer back ---"
result = queue.read_buffer(buffer, device: device)
read_data = result.unpack("f*")
puts "Read back: #{read_data.inspect}"

puts "\n--- 4. Buffer mapping (mapped_at_creation) ---"
map_buffer = device.create_buffer(
  label: "mappable buffer",
  size: 16,
  usage: [:copy_src, :copy_dst],
  mapped_at_creation: true
)

map_buffer.mapped_range.write_floats([100.0, 200.0, 300.0, 400.0])
puts "Wrote data via mapped_at_creation: [100.0, 200.0, 300.0, 400.0]"
puts "Map state before unmap: #{map_buffer.map_state}"
map_buffer.unmap
puts "Map state after unmap: #{map_buffer.map_state}"

read_back = queue.read_buffer(map_buffer, device: device)
puts "Read back via queue: #{read_back.unpack('f*').inspect}"

puts "\n--- 5. Buffer copy ---"
src_buffer = device.create_buffer_with_data(
  data: [1.0, 2.0, 3.0, 4.0],
  usage: [:copy_src]
)
dst_buffer = device.create_buffer(
  size: 16,
  usage: [:copy_dst, :map_read]
)

encoder = device.create_command_encoder
encoder.copy_buffer_to_buffer(
  source: src_buffer,
  destination: dst_buffer,
  size: 16
)
queue.submit([encoder.finish])

dst_buffer.map_sync(:read)
copied = dst_buffer.read_mapped_floats(count: 4)
puts "Copied data: #{copied.inspect}"
dst_buffer.unmap

[buffer, map_buffer, src_buffer, dst_buffer, encoder].each(&:release)
device.release
adapter.release
instance.release
puts "\nDone!"
