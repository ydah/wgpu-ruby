# frozen_string_literal: true

lib_dir = File.expand_path("../../lib", __dir__)
$LOAD_PATH.unshift(lib_dir) unless $LOAD_PATH.include?(lib_dir)

require "wgpu/native/installer"

begin
  installer = WGPU::Native::Installer.new
  if ENV["WGPU_LIB_PATH"]
    puts "Using custom wgpu-native from WGPU_LIB_PATH: #{installer.install}"
  else
    installer.install
  end
rescue WGPU::Native::InstallError => error
  abort error.message
end

File.write("Makefile", <<~MAKEFILE)
  .PHONY: install clean

  install:
  \t@echo "wgpu-native is ready"

  clean:
  \t@echo "Nothing to clean"
MAKEFILE

puts "Done!"
