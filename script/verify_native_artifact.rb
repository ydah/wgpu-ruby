# frozen_string_literal: true

require "wgpu"

expected = ENV.fetch("EXPECTED_ARCHIVE")
actual = WGPU::Native::Distribution.artifact_for.fetch(:archive)

abort "expected #{expected}, got #{actual}" unless actual == expected

puts "Verified native artifact: #{actual}"
