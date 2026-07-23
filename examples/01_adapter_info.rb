#!/usr/bin/env ruby
# frozen_string_literal: true

# Purpose: enumerate adapters and print their information, features, and limits.
# APIs: Instance#enumerate_adapters, Instance#request_adapter, Adapter info/features/limits.
# Expected: at least one adapter is printed on a configured GPU or lavapipe host.

require_relative "../lib/wgpu"

instance = WGPU::Instance.new
puts "WebGPU Instance created"

puts "\n=== Available Adapters ==="
adapters = instance.enumerate_adapters
adapters.each_with_index do |adapter, i|
  info = adapter.info
  puts "\nAdapter #{i}:"
  puts "  Device:       #{info[:device]}"
  puts "  Vendor:       #{info[:vendor]}"
  puts "  Description:  #{info[:description]}"
  puts "  Backend:      #{info[:backend_type]}"
  puts "  Type:         #{info[:adapter_type]}"
  puts "  Vendor ID:    0x#{info[:vendor_id].to_s(16)}"
  puts "  Device ID:    0x#{info[:device_id].to_s(16)}"
end

puts "\n=== Default Adapter (High Performance) ==="
adapter = instance.request_adapter(power_preference: :high_performance)
info = adapter.info
puts "Selected: #{info[:device]} (#{info[:backend_type]})"

puts "\n=== Supported Features ==="
features = adapter.features
if features.empty?
  puts "  (no optional features)"
else
  features.each { |f| puts "  - #{f}" }
end

puts "\n=== Limits ==="
limits = adapter.limits
puts "  Max Texture 2D:          #{limits[:max_texture_dimension_2d]}"
puts "  Max Buffer Size:         #{limits[:max_buffer_size] / (1024 * 1024)} MB"
puts "  Max Bind Groups:         #{limits[:max_bind_groups]}"
puts "  Max Compute Workgroups:  #{limits[:max_compute_workgroups_per_dimension]}"
puts "  Max Workgroup Size X:    #{limits[:max_compute_workgroup_size_x]}"

adapters.each(&:release)
adapter.release
instance.release
puts "\nDone!"
