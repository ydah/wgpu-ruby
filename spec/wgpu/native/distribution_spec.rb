# frozen_string_literal: true

require "tmpdir"
require_relative "../../../lib/wgpu/native/distribution"

RSpec.describe WGPU::Native::Distribution, :no_native do
  describe ".artifact_for" do
    {
      "x86_64-linux" => "wgpu-linux-x86_64-release.zip",
      "aarch64-linux" => "wgpu-linux-aarch64-release.zip",
      "x86_64-darwin" => "wgpu-macos-x86_64-release.zip",
      "arm64-darwin" => "wgpu-macos-aarch64-release.zip",
      "x64-mingw-ucrt" => "wgpu-windows-x86_64-msvc-release.zip"
    }.each do |platform, archive|
      it "maps #{platform}" do
        expect(described_class.artifact_for(platform)[:archive]).to eq(archive)
      end
    end

    it "explains how to use an unsupported platform" do
      expect { described_class.artifact_for("aarch64-linux-musl") }
        .to raise_error(LoadError, /WGPU_LIB_PATH/)
    end
  end

  describe ".primary_cache_dir" do
    let(:home) { "/home/tester" }

    it "prefers WGPU_CACHE_DIR" do
      env = { "WGPU_CACHE_DIR" => "/cache/wgpu", "XDG_CACHE_HOME" => "/cache/xdg" }
      expect(described_class.primary_cache_dir(env:, home:, host_os: "linux"))
        .to eq(File.join("/cache/wgpu", described_class::VERSION))
    end

    it "uses XDG_CACHE_HOME before the OS default" do
      env = { "XDG_CACHE_HOME" => "/cache/xdg" }
      expect(described_class.primary_cache_dir(env:, home:, host_os: "linux"))
        .to eq(File.join("/cache/xdg", "wgpu-ruby", described_class::VERSION))
    end

    it "uses the macOS cache convention" do
      expect(described_class.primary_cache_dir(env: {}, home:, host_os: "darwin"))
        .to eq(File.join(home, "Library", "Caches", "wgpu-ruby", described_class::VERSION))
    end

    it "uses LOCALAPPDATA on Windows" do
      env = { "LOCALAPPDATA" => "C:/Users/tester/AppData/Local" }
      expect(described_class.primary_cache_dir(env:, home:, host_os: "mingw32"))
        .to eq(File.join(env["LOCALAPPDATA"], "wgpu-ruby", described_class::VERSION))
    end
  end
end
