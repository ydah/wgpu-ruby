# frozen_string_literal: true

require "digest"
require "fileutils"
require_relative "../lib/wgpu/native/distribution"

source_path = ARGV.fetch(0) do
  abort "Usage: bundle exec ruby script/update_abi_fixture.rb PATH_TO_WEBGPU_H"
end
source_path = File.expand_path(source_path)
source = File.binread(source_path)
enum_declarations = source.scan(
  /typedef enum WGPU\w+\s*\{.*?\}\s*WGPU\w+(?:\s+WGPU_ENUM_ATTRIBUTE)?;/m
)
abort "No WGPU enum declarations found in #{source_path}" if enum_declarations.empty?

version = WGPU::Native::Distribution::VERSION
fixture_path = File.expand_path(
  "../lib/wgpu/native/fixtures/webgpu-#{version}-enums.h",
  __dir__
)
header = <<~HEADER
  /*
   * Generated from include/webgpu/webgpu.h in the official wgpu-native #{version}
   * release artifact. Only enum declarations consumed by AbiVerifier are kept.
   * Source SHA-256: #{Digest::SHA256.hexdigest(source)}
   * Regenerate: bundle exec ruby script/update_abi_fixture.rb PATH_TO_WEBGPU_H
   */

HEADER

FileUtils.mkdir_p(File.dirname(fixture_path))
File.binwrite(fixture_path, header + enum_declarations.join("\n\n") + "\n")
puts "Wrote #{enum_declarations.length} enum declarations to #{fixture_path}"
