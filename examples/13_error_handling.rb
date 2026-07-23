# frozen_string_literal: true

# Purpose: demonstrate typed Ruby-side validation errors with operation labels.
# APIs: Device#create_buffer, WGPU::BufferError.
# Expected: prints a labeled BufferError and "Error handling PASSED".

require_relative "../lib/wgpu"

instance = WGPU::Instance.new
adapter = instance.request_adapter(timeout: 10)
device = adapter.request_device(timeout: 10)

begin
  device.create_buffer(label: "invalid example buffer", size: 64, usage: :not_a_usage)
  abort "invalid buffer usage unexpectedly succeeded"
rescue WGPU::BufferError => e
  abort "error omitted label" unless e.message.include?("invalid example buffer")

  puts e.message
  puts "Error handling PASSED"
ensure
  device.release
  adapter.release
  instance.release
end
