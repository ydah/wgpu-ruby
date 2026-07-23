# frozen_string_literal: true

require "fileutils"
require "stringio"
require "tmpdir"
require "zip"
require_relative "../../../lib/wgpu/native/installer"

RSpec.describe WGPU::Native::Installer, :no_native do
  let(:output) { StringIO.new }

  it "rejects and removes an archive with the wrong checksum" do
    Dir.mktmpdir do |directory|
      archive = File.join(directory, "artifact.zip")
      File.write(archive, "tampered")
      installer = described_class.new(output:)

      expect { installer.send(:verify_checksum!, archive, "0" * 64) }
        .to raise_error(WGPU::Native::InstallError, /SHA-256 mismatch/)
      expect(File.exist?(archive)).to be(false)
    end
  end

  it "extracts a fixture archive with rubyzip" do
    Dir.mktmpdir do |directory|
      archive = File.join(directory, "artifact.zip")
      destination = File.join(directory, "out")
      Zip::File.open(archive, create: true) do |zip|
        zip.get_output_stream("lib/libwgpu_native.dylib") { |file| file.write("fixture") }
      end

      described_class.new(output:).send(:extract_zip, archive, destination)

      expect(File.binread(File.join(destination, "lib", "libwgpu_native.dylib"))).to eq("fixture")
    end
  end

  it "reuses a library from the legacy cache" do
    Dir.mktmpdir do |home|
      artifact = WGPU::Native::Distribution.artifact_for("arm64-darwin")
      legacy_library = File.join(
        WGPU::Native::Distribution.legacy_cache_dir(home:),
        "lib",
        artifact[:library]
      )
      FileUtils.mkdir_p(File.dirname(legacy_library))
      File.write(legacy_library, "fixture")
      env = { "WGPU_CACHE_DIR" => File.join(home, "new-cache") }
      installer = described_class.new(
        platform: "arm64-darwin",
        env:,
        home:,
        host_os: "darwin",
        output:
      )

      expect(installer.install).to eq(legacy_library)
    end
  end

  it "validates WGPU_LIB_PATH before skipping installation" do
    installer = described_class.new(env: { "WGPU_LIB_PATH" => "/missing/wgpu" }, output:)

    expect { installer.install }.to raise_error(WGPU::Native::InstallError, /non-existent file/)
  end
end
