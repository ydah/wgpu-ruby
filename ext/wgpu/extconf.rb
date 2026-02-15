# frozen_string_literal: true

require "fileutils"
require "net/http"
require "uri"

WGPU_VERSION = "v27.0.4.0"
GITHUB_RELEASE_URL = "https://github.com/gfx-rs/wgpu-native/releases/download/#{WGPU_VERSION}"

PLATFORM_MAP = {
  /x86_64-linux/ => { file: "wgpu-linux-x86_64-release.zip", lib: "libwgpu_native.so" },
  /aarch64-linux/ => { file: "wgpu-linux-aarch64-release.zip", lib: "libwgpu_native.so" },
  /x86_64-darwin/ => { file: "wgpu-macos-x86_64-release.zip", lib: "libwgpu_native.dylib" },
  /arm64-darwin/ => { file: "wgpu-macos-aarch64-release.zip", lib: "libwgpu_native.dylib" },
  /mingw|mswin/ => { file: "wgpu-windows-x86_64-msvc-release.zip", lib: "wgpu_native.dll" }
}.freeze

def detect_platform
  PLATFORM_MAP.each do |pattern, info|
    return info if RUBY_PLATFORM =~ pattern
  end
  abort "Unsupported platform: #{RUBY_PLATFORM}\nSupported: #{PLATFORM_MAP.keys.map(&:inspect).join(", ")}"
end

def cache_dir
  File.join(Dir.home, ".cache", "wgpu-ruby", WGPU_VERSION)
end

def windows?
  RUBY_PLATFORM =~ /mingw|mswin/
end

def curl_available?
  if windows?
    system("where curl >nul 2>&1")
  else
    system("which curl >/dev/null 2>&1")
  end
end

def download_with_curl(url, dest)
  system("curl", "-fsSL", "-o", dest, url)
end

def download_with_ruby(url, dest, redirects = 5)
  raise "Too many redirects" if redirects == 0

  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = (uri.scheme == "https")
  http.open_timeout = 10
  http.read_timeout = 120

  request = Net::HTTP::Get.new(uri.request_uri)

  http.request(request) do |response|
    case response
    when Net::HTTPRedirection
      download_with_ruby(response["location"], dest, redirects - 1)
    when Net::HTTPSuccess
      File.open(dest, "wb") do |file|
        response.read_body { |chunk| file.write(chunk) }
      end
    else
      return false
    end
  end
  true
end

def download_file(url, dest)
  return if curl_available? && download_with_curl(url, dest)
  return if download_with_ruby(url, dest)

  abort "Download failed: #{url}"
end

def extract_with_rubyzip(zip_path, dest_dir)
  require "zip"
  Zip::File.open(zip_path) do |zip_file|
    zip_file.each do |entry|
      dest_path = File.join(dest_dir, entry.name)
      FileUtils.mkdir_p(File.dirname(dest_path))
      entry.extract(dest_path) { true }
    end
  end
  true
rescue LoadError
  false
end

def extract_with_powershell(zip_path, dest_dir)
  return false unless windows?

  system("powershell", "-Command", "Expand-Archive -Force -Path '#{zip_path}' -DestinationPath '#{dest_dir}'")
end

def extract_with_unzip(zip_path, dest_dir)
  system("unzip", "-o", "-q", zip_path, "-d", dest_dir)
end

def extract_zip(zip_path, dest_dir)
  return if extract_with_rubyzip(zip_path, dest_dir)
  return if windows? && extract_with_powershell(zip_path, dest_dir)
  return if extract_with_unzip(zip_path, dest_dir)

  abort "Failed to extract zip. Please install 'rubyzip' gem."
end

def lib_dir
  File.join(cache_dir, "lib")
end

def download_wgpu_native
  platform = detect_platform
  lib_path = File.join(lib_dir, platform[:lib])

  if File.exist?(lib_path)
    puts "wgpu-native already cached at #{lib_path}"
    return lib_path
  end

  FileUtils.mkdir_p(cache_dir)

  url = "#{GITHUB_RELEASE_URL}/#{platform[:file]}"
  zip_path = File.join(cache_dir, platform[:file])

  puts "Downloading wgpu-native #{WGPU_VERSION} from GitHub..."
  puts "  URL: #{url}"
  download_file(url, zip_path)

  puts "Extracting to #{cache_dir}..."
  extract_zip(zip_path, cache_dir)

  FileUtils.rm_f(zip_path)

  unless File.exist?(lib_path)
    abort "Failed to find #{platform[:lib]} after extraction"
  end

  puts "wgpu-native installed successfully!"
  lib_path
end

if ENV["WGPU_LIB_PATH"]
  puts "Using custom wgpu-native from WGPU_LIB_PATH: #{ENV["WGPU_LIB_PATH"]}"
else
  download_wgpu_native
end

File.write("Makefile", <<~MAKEFILE)
  .PHONY: install clean

  install:
  \t@echo "wgpu-native is ready"

  clean:
  \t@echo "Nothing to clean"
MAKEFILE

puts "Done!"
