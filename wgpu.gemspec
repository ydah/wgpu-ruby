# frozen_string_literal: true

require_relative "lib/wgpu/version"

Gem::Specification.new do |spec|
  spec.name = "wgpu"
  spec.version = WGPU::VERSION
  spec.authors = ["Yudai Takada"]
  spec.email = ["t.yudai92@gmail.com"]

  spec.summary = "Ruby bindings for WebGPU via wgpu-native"
  spec.description = "Ruby bindings for the WebGPU API, providing GPU compute and graphics capabilities through the wgpu-native library."
  spec.homepage = "https://github.com/ydah/wgpu-ruby"
  spec.licenses = ["MIT", "Apache-2.0"]
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/ydah/wgpu-ruby"

  spec.files = Dir["lib/**/*", "ext/**/*", "README.md", "LICENSE-MIT", "LICENSE-APACHE"]
  spec.require_paths = ["lib"]

  spec.extensions = ["ext/wgpu/extconf.rb"]

  spec.add_dependency "ffi", "~> 1.15"
  spec.add_dependency "rubyzip", "~> 2.3"
  spec.add_dependency "sdl3", "~> 1.0.0"
end
