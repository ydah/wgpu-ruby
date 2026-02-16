# frozen_string_literal: true

require "ffi"
require "rbconfig"

module WGPU
  module Native
    extend FFI::Library

    WGPU_VERSION = "v27.0.4.0"

    class << self
      def library_path
        if ENV["WGPU_LIB_PATH"]
          path = ENV["WGPU_LIB_PATH"]
          raise LoadError, "WGPU_LIB_PATH points to non-existent file: #{path}" unless File.exist?(path)
          return path
        end

        cached_path = File.join(cache_dir, "lib", library_name)
        return cached_path if File.exist?(cached_path)

        raise LoadError, <<~MSG
          wgpu-native library not found.
          Expected at: #{cached_path}

          Try reinstalling the gem:
            gem install wgpu

          Or set WGPU_LIB_PATH environment variable to your custom wgpu-native build.
        MSG
      end

      def cache_dir
        File.join(Dir.home, ".cache", "wgpu-ruby", WGPU_VERSION)
      end

      def library_name
        case host_os
        when /linux/ then "libwgpu_native.so"
        when /darwin/ then "libwgpu_native.dylib"
        when /mingw|mswin/ then "wgpu_native.dll"
        else raise LoadError, "Unsupported OS: #{host_os}"
        end
      end

      private

      def host_os
        RbConfig::CONFIG["host_os"]
      end
    end

    ffi_lib library_path
  end
end

require_relative "enums"
require_relative "structs"
require_relative "callbacks"
require_relative "functions"
require_relative "capabilities"
