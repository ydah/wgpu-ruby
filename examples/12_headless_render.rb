#!/usr/bin/env ruby
# frozen_string_literal: true

# Purpose: render a triangle to a texture without SDL3 or a surface.
# APIs: render pipeline/pass, texture readback, aligned bytes_per_row.
# Expected: center is red, corner is blue, and the script prints PASSED.

require_relative "headless_rendering"

output_path = ENV["WGPU_HEADLESS_OUTPUT"]
result = HeadlessRendering.run(output_path: output_path)

center_ok = result[:center].zip([255, 0, 0, 255]).all? { |actual, expected| (actual - expected).abs <= 1 }
corner_ok = result[:corner].zip([0, 0, 255, 255]).all? { |actual, expected| (actual - expected).abs <= 1 }

puts "Center pixel: #{result[:center].inspect}"
puts "Corner pixel: #{result[:corner].inspect}"
puts "Wrote #{output_path}" if output_path
abort "Headless render pixel verification FAILED" unless center_ok && corner_ok
puts "Headless render pixel verification PASSED"
