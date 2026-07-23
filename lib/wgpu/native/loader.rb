# frozen_string_literal: true

require "ffi"
require_relative "distribution"

module WGPU
  module Native
    extend FFI::Library

    class << self
      def library_path
        if ENV["WGPU_LIB_PATH"] && !ENV["WGPU_LIB_PATH"].empty?
          path = File.expand_path(ENV["WGPU_LIB_PATH"])
          raise LoadError, "WGPU_LIB_PATH points to non-existent file: #{path}" unless File.exist?(path)
          return path
        end

        cached_path = Distribution.library_paths.find { |path| File.file?(path) }
        return cached_path if cached_path

        raise LoadError, <<~MSG
          wgpu-native library not found.
          Searched:
            #{Distribution.library_paths.join("\n  ")}

          Try reinstalling the gem:
            gem install wgpu

          Or set WGPU_LIB_PATH environment variable to your custom wgpu-native build.
          See docs/installation.md for manual installation instructions.
        MSG
      end

      def cache_dir
        Distribution.primary_cache_dir
      end

      def library_name
        Distribution.artifact_for.fetch(:library)
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
