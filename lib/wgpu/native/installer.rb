# frozen_string_literal: true

require "digest"
require "fileutils"
require "net/http"
require "uri"

require_relative "distribution"

module WGPU
  module Native
    class InstallError < StandardError; end

    class Installer
      attr_reader :platform

      def initialize(platform: RUBY_PLATFORM, env: ENV, home: Dir.home,
                     host_os: RbConfig::CONFIG["host_os"], output: $stdout)
        @platform = platform
        @env = env
        @home = home
        @host_os = host_os
        @output = output
      end

      def install
        return custom_library_path if custom_library_path

        artifact = Distribution.artifact_for(platform)
        cached_path = existing_library_path(artifact)
        if cached_path
          @output.puts "wgpu-native already cached at #{cached_path}"
          return cached_path
        end

        install_artifact(artifact)
      rescue LoadError, InstallError => error
        raise InstallError, "#{error.message}\n\n#{recovery_instructions}"
      end

      def clean_path
        Distribution.primary_cache_dir(env: @env, home: @home, host_os: @host_os)
      end

      private

      def custom_library_path
        path = @env["WGPU_LIB_PATH"]
        return if path.nil? || path.empty?
        raise InstallError, "WGPU_LIB_PATH points to a non-existent file: #{path}" unless File.file?(path)

        File.expand_path(path)
      end

      def existing_library_path(artifact)
        Distribution.cache_directories(env: @env, home: @home, host_os: @host_os).each do |directory|
          path = File.join(directory, "lib", artifact.fetch(:library))
          return path if File.file?(path)
        end
        nil
      end

      def install_artifact(artifact)
        cache_dir = clean_path
        archive_path = File.join(cache_dir, artifact.fetch(:archive))
        library_path = File.join(cache_dir, "lib", artifact.fetch(:library))
        FileUtils.mkdir_p(cache_dir)

        @output.puts "Downloading wgpu-native #{Distribution::VERSION} from GitHub..."
        @output.puts "  URL: #{Distribution.release_url(artifact)}"
        download_file(Distribution.release_url(artifact), archive_path)
        verify_checksum!(archive_path, artifact.fetch(:sha256))

        @output.puts "Extracting to #{cache_dir}..."
        extract_zip(archive_path, cache_dir)
        raise InstallError, "Archive did not contain lib/#{artifact.fetch(:library)}" unless File.file?(library_path)

        @output.puts "wgpu-native installed successfully!"
        library_path
      ensure
        FileUtils.rm_f(archive_path) if archive_path
      end

      def verify_checksum!(path, expected)
        actual = Digest::SHA256.file(path).hexdigest
        return if actual == expected

        FileUtils.rm_f(path)
        raise InstallError, "SHA-256 mismatch for #{File.basename(path)} (expected #{expected}, got #{actual})"
      end

      def download_file(url, destination)
        return if curl_available? && download_with_curl(url, destination)
        return if download_with_ruby(url, destination)

        raise InstallError, "Download failed: #{url}"
      end

      def curl_available?
        system("curl", "--version", out: File::NULL, err: File::NULL)
      end

      def download_with_curl(url, destination)
        system("curl", "-fsSL", "-o", destination, url)
      end

      def download_with_ruby(url, destination, redirects = 5)
        raise InstallError, "Too many redirects while downloading #{url}" if redirects.zero?

        uri = URI.parse(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"
        http.open_timeout = 10
        http.read_timeout = 120

        http.request(Net::HTTP::Get.new(uri.request_uri)) do |response|
          case response
          when Net::HTTPRedirection
            location = response["location"]
            raise InstallError, "Redirect response did not include a location" unless location

            location = URI.join(url, location).to_s
            return download_with_ruby(location, destination, redirects - 1)
          when Net::HTTPSuccess
            File.open(destination, "wb") do |file|
              response.read_body { |chunk| file.write(chunk) }
            end
            return true
          end
        end

        false
      rescue SystemCallError, SocketError, URI::InvalidURIError => error
        @output.puts "Ruby download failed: #{error.message}"
        false
      end

      def extract_zip(archive_path, destination)
        return if extract_with_rubyzip(archive_path, destination)
        return if windows? && extract_with_powershell(archive_path, destination)
        return if extract_with_unzip(archive_path, destination)

        raise InstallError, "Failed to extract zip; install the rubyzip gem or a supported system extractor"
      end

      def extract_with_rubyzip(archive_path, destination)
        require "zip"
        destination_root = "#{File.expand_path(destination)}#{File::SEPARATOR}"

        Zip::File.open(archive_path) do |zip_file|
          zip_file.each do |entry|
            target = File.expand_path(entry.name, destination)
            unless target.start_with?(destination_root)
              raise InstallError, "Archive entry escapes destination: #{entry.name}"
            end

            FileUtils.mkdir_p(entry.directory? ? target : File.dirname(target))
            entry.extract(target) { true } unless entry.directory?
          end
        end
        true
      rescue LoadError
        false
      end

      def extract_with_powershell(archive_path, destination)
        system(
          "powershell",
          "-NoProfile",
          "-Command",
          "Expand-Archive -Force -LiteralPath '#{archive_path}' -DestinationPath '#{destination}'"
        )
      end

      def extract_with_unzip(archive_path, destination)
        system("unzip", "-o", "-q", archive_path, "-d", destination)
      end

      def windows?
        /mingw|mswin/.match?(platform)
      end

      def recovery_instructions
        <<~INSTRUCTIONS.chomp
          Download the matching #{Distribution::VERSION} artifact manually and set:
            WGPU_LIB_PATH=/absolute/path/to/the/wgpu-native/shared-library
          See docs/installation.md for platform details.
        INSTRUCTIONS
      end
    end
  end
end
