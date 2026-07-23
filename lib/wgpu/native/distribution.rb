# frozen_string_literal: true

require "rbconfig"

module WGPU
  module Native
    module Distribution
      VERSION = "v27.0.4.0"
      RELEASE_BASE_URL = "https://github.com/gfx-rs/wgpu-native/releases/download/#{VERSION}"
      UNIMPLEMENTED_CAPABILITIES = {
        compilation_info: [VERSION].freeze,
        buffer_map_state: [VERSION].freeze
      }.freeze

      ARTIFACTS = [
        {
          pattern: /x86_64-linux/,
          archive: "wgpu-linux-x86_64-release.zip",
          library: "libwgpu_native.so",
          sha256: "271481ef76fbf3ea09631a6079e9493636ecf813cd9c92306c44a1a452991ba1"
        },
        {
          pattern: /aarch64-linux/,
          archive: "wgpu-linux-aarch64-release.zip",
          library: "libwgpu_native.so",
          sha256: "a2f22248200997b69373273b10d50a58164f6ed840877289f3e46bff317b134e"
        },
        {
          pattern: /x86_64-darwin/,
          archive: "wgpu-macos-x86_64-release.zip",
          library: "libwgpu_native.dylib",
          sha256: "660fe9be59b555ec1d7c839e5cf8b6c71762938af61ab444a7a58dd87970dba2"
        },
        {
          pattern: /arm64-darwin/,
          archive: "wgpu-macos-aarch64-release.zip",
          library: "libwgpu_native.dylib",
          sha256: "15367c26fdbe6892db35007d39f3883593384e777360b70e6bd704cb5dedde53"
        },
        {
          pattern: /(?:x64|x86_64)-(?:mingw|mswin)/,
          archive: "wgpu-windows-x86_64-msvc-release.zip",
          library: "wgpu_native.dll",
          sha256: "f14ca334b4d253881bde2605bd147f332178d705f56fbd74f81458797c77fce1"
        }
      ].map(&:freeze).freeze

      module_function

      def artifact_for(platform = RUBY_PLATFORM)
        raise LoadError, unsupported_platform_message(platform) if platform.include?("musl")

        artifact = ARTIFACTS.find { |candidate| candidate[:pattern].match?(platform) }
        return artifact if artifact

        raise LoadError, unsupported_platform_message(platform)
      end

      def primary_cache_dir(env: ENV, home: Dir.home, host_os: RbConfig::CONFIG["host_os"])
        override = present_value(env["WGPU_CACHE_DIR"])
        return File.join(File.expand_path(override), VERSION) if override

        xdg_cache = present_value(env["XDG_CACHE_HOME"])
        return File.join(File.expand_path(xdg_cache), "wgpu-ruby", VERSION) if xdg_cache

        File.join(default_cache_base(env:, home:, host_os:), "wgpu-ruby", VERSION)
      end

      def legacy_cache_dir(home: Dir.home)
        File.join(File.expand_path(home), ".cache", "wgpu-ruby", VERSION)
      end

      def cache_directories(env: ENV, home: Dir.home, host_os: RbConfig::CONFIG["host_os"])
        [primary_cache_dir(env:, home:, host_os:), legacy_cache_dir(home:)].uniq
      end

      def library_paths(platform: RUBY_PLATFORM, env: ENV, home: Dir.home,
                        host_os: RbConfig::CONFIG["host_os"])
        library = artifact_for(platform)[:library]
        cache_directories(env:, home:, host_os:).map { |directory| File.join(directory, "lib", library) }
      end

      def release_url(artifact)
        "#{RELEASE_BASE_URL}/#{artifact.fetch(:archive)}"
      end

      def capability_implemented?(name)
        !UNIMPLEMENTED_CAPABILITIES.fetch(name, []).include?(VERSION)
      end

      def unsupported_platform_message(platform)
        supported = ARTIFACTS.map { |artifact| artifact[:pattern].inspect }.join(", ")
        <<~MESSAGE.chomp
          Unsupported platform: #{platform}
          Supported 64-bit platforms: #{supported}
          Build wgpu-native for this host and set WGPU_LIB_PATH to the shared library.
        MESSAGE
      end

      def default_cache_base(env:, home:, host_os:)
        case host_os
        when /darwin/
          File.join(File.expand_path(home), "Library", "Caches")
        when /mingw|mswin/
          local_app_data = present_value(env["LOCALAPPDATA"])
          local_app_data || File.join(File.expand_path(home), "AppData", "Local")
        else
          File.join(File.expand_path(home), ".cache")
        end
      end
      private_class_method :default_cache_base

      def present_value(value)
        value unless value.nil? || value.empty?
      end
      private_class_method :present_value
    end

    WGPU_VERSION = Distribution::VERSION
  end
end
