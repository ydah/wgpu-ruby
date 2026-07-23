# frozen_string_literal: true

require "fileutils"
require "stringio"
require "tmpdir"
require "zip"
require_relative "../../../lib/wgpu/native/installer"

RSpec.describe WGPU::Native::Installer, :no_native do
  let(:output) { StringIO.new }

  def http_response(response_class, body: nil, headers: {})
    response = response_class.new("1.1", "fixture", "Fixture response")
    headers.each { |name, value| response[name] = value }
    response.define_singleton_method(:read_body) do |&block|
      block.call(body) if body
    end
    response
  end

  def http_client(response)
    instance_double(Net::HTTP).tap do |client|
      allow(client).to receive(:use_ssl=)
      allow(client).to receive(:open_timeout=)
      allow(client).to receive(:read_timeout=)
      allow(client).to receive(:request) do |_request, &block|
        block.call(response)
      end
    end
  end

  def create_fixture_archive(path, library:)
    Zip::File.open(path, create: true) do |zip|
      zip.get_output_stream(File.join("lib", library)) { |file| file.write("fixture library") }
    end
  end

  it "downloads with curl when curl succeeds" do
    Dir.mktmpdir do |directory|
      destination = File.join(directory, "artifact.zip")
      commands = []
      command_runner = lambda do |*command, **options|
        commands << [command, options]
        File.binwrite(destination, "curl body") if command.include?("-o")
        true
      end
      installer = described_class.new(output:, command_runner:)

      installer.send(:download_file, "https://example.test/artifact.zip", destination)

      expect(File.binread(destination)).to eq("curl body")
      expect(commands.map(&:first)).to eq(
        [
          ["curl", "--version"],
          ["curl", "-fsSL", "-o", destination, "https://example.test/artifact.zip"]
        ]
      )
    end
  end

  it "falls back to Ruby HTTP when curl download fails" do
    Dir.mktmpdir do |directory|
      destination = File.join(directory, "artifact.zip")
      command_runner = lambda do |*command, **|
        command == ["curl", "--version"]
      end
      response = http_response(Net::HTTPOK, body: "HTTP body")
      installer = described_class.new(
        output:,
        command_runner:,
        http_factory: ->(_uri) { http_client(response) }
      )

      installer.send(:download_file, "https://example.test/artifact.zip", destination)

      expect(File.binread(destination)).to eq("HTTP body")
    end
  end

  it "streams a successful HTTP response to the destination" do
    Dir.mktmpdir do |directory|
      destination = File.join(directory, "artifact.zip")
      response = http_response(Net::HTTPOK, body: "fixture body")
      installer = described_class.new(output:, http_factory: ->(_uri) { http_client(response) })

      expect(
        installer.send(:download_with_ruby, "https://example.test/artifact.zip", destination)
      ).to be(true)
      expect(File.binread(destination)).to eq("fixture body")
    end
  end

  it "follows relative HTTP redirects" do
    Dir.mktmpdir do |directory|
      destination = File.join(directory, "artifact.zip")
      requested_urls = []
      responses = {
        "https://example.test/releases/artifact.zip" => http_response(
          Net::HTTPFound,
          headers: { "location" => "../downloads/artifact.zip" }
        ),
        "https://example.test/downloads/artifact.zip" => http_response(Net::HTTPOK, body: "redirected")
      }
      installer = described_class.new(
        output:,
        http_factory: lambda do |uri|
          requested_urls << uri.to_s
          http_client(responses.fetch(uri.to_s))
        end
      )

      expect(
        installer.send(:download_with_ruby, "https://example.test/releases/artifact.zip", destination)
      ).to be(true)
      expect(requested_urls).to eq(
        [
          "https://example.test/releases/artifact.zip",
          "https://example.test/downloads/artifact.zip"
        ]
      )
      expect(File.binread(destination)).to eq("redirected")
    end
  end

  it "rejects redirects without a location" do
    response = http_response(Net::HTTPFound)
    installer = described_class.new(output:, http_factory: ->(_uri) { http_client(response) })

    expect do
      installer.send(:download_with_ruby, "https://example.test/artifact.zip", "/unused")
    end.to raise_error(WGPU::Native::InstallError, /did not include a location/)
  end

  it "rejects redirects beyond the configured limit" do
    response = http_response(Net::HTTPFound, headers: { "location" => "/again" })
    installer = described_class.new(output:, http_factory: ->(_uri) { http_client(response) })

    expect do
      installer.send(:download_with_ruby, "https://example.test/artifact.zip", "/unused", 1)
    end.to raise_error(WGPU::Native::InstallError, /Too many redirects/)
  end

  it "returns false for an unsuccessful HTTP response" do
    response = http_response(Net::HTTPNotFound)
    installer = described_class.new(output:, http_factory: ->(_uri) { http_client(response) })

    expect(
      installer.send(:download_with_ruby, "https://example.test/missing.zip", "/unused")
    ).to be(false)
  end

  it "falls back from unavailable rubyzip through PowerShell to unzip on Windows" do
    commands = []
    command_runner = lambda do |*command, **|
      commands << command
      command.first == "unzip"
    end
    installer = described_class.new(
      platform: "x64-mingw-ucrt",
      output:,
      command_runner:,
      zip_file_loader: -> { raise LoadError }
    )

    installer.send(:extract_zip, "artifact.zip", "destination")

    expect(commands.map(&:first)).to eq(%w[powershell unzip])
  end

  it "raises when every zip extractor fails" do
    installer = described_class.new(
      platform: "x64-mingw-ucrt",
      output:,
      command_runner: ->(*, **) { false },
      zip_file_loader: -> { raise LoadError }
    )

    expect do
      installer.send(:extract_zip, "artifact.zip", "destination")
    end.to raise_error(WGPU::Native::InstallError, /Failed to extract zip/)
  end

  it "installs a checksummed fixture archive through the full install flow" do
    Dir.mktmpdir do |directory|
      library = "libwgpu_native_fixture.so"
      fixture_archive = File.join(directory, "fixture-source.zip")
      cache_dir = File.join(directory, "cache")
      create_fixture_archive(fixture_archive, library:)
      artifact = {
        archive: "fixture.zip",
        library:,
        sha256: Digest::SHA256.file(fixture_archive).hexdigest
      }
      distribution = Module.new
      distribution.const_set(:VERSION, "fixture-version")
      distribution.define_singleton_method(:artifact_for) { |_platform| artifact }
      distribution.define_singleton_method(:primary_cache_dir) { |**| cache_dir }
      distribution.define_singleton_method(:cache_directories) { |**| [cache_dir] }
      distribution.define_singleton_method(:release_url) { |_artifact| "https://example.test/fixture.zip" }
      command_runner = lambda do |*command, **|
        next true if command == ["curl", "--version"]

        FileUtils.cp(fixture_archive, command.fetch(3))
        true
      end
      installer = described_class.new(
        platform: "fixture-platform",
        output:,
        command_runner:,
        distribution:
      )

      installed_library = installer.install

      expect(installed_library).to eq(File.join(cache_dir, "lib", library))
      expect(File.binread(installed_library)).to eq("fixture library")
      expect(File.exist?(File.join(cache_dir, artifact[:archive]))).to be(false)
    end
  end

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
