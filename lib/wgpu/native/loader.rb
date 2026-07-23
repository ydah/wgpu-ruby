# frozen_string_literal: true

require "ffi"
require_relative "distribution"

module WGPU
  module Native
    module OptionalFunctions
      # Attaches a native function without failing library initialization.
      #
      # @param name [Symbol] exported function name
      # @param arguments [Array] FFI argument types
      # @param result [Symbol, FFI::Type] FFI return type
      # @return [void]
      def attach_optional_function(name, arguments, result)
        attach_function(name, arguments, result)
        optional_functions[name] = true
      rescue FFI::NotFoundError
        optional_functions[name] = false
        define_singleton_method(name) do |*|
          raise WGPU::Error,
            "Optional wgpu-native function #{name} is unavailable in the loaded library " \
            "(expected #{Distribution::VERSION})"
        end
      end

      def optional_function_available?(name)
        optional_functions.fetch(name, false)
      end

      # Returns availability information for optional native functions.
      #
      # @return [Hash{Symbol => Boolean}] immutable capability snapshot
      def optional_capabilities
        optional_functions.dup.freeze
      end

      private

      def optional_functions
        @optional_functions ||= {}
      end
    end

    extend FFI::Library
    extend OptionalFunctions

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

      # Returns the preferred native-library cache directory.
      #
      # @return [String] absolute cache directory
      def cache_dir
        Distribution.primary_cache_dir
      end

      # Returns the shared-library filename for this platform.
      #
      # @return [String] platform-specific filename
      # @raise [LoadError] if the platform is unsupported
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
