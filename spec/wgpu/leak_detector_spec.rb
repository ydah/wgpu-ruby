# frozen_string_literal: true

require "open3"
require "rbconfig"

RSpec.describe "WGPU leak detector", :no_native do
  let(:library_path) { File.expand_path("../../lib", __dir__) }
  let(:script) do
    <<~RUBY
      require "wgpu/native_resource"

      class LeakyResource
        attr_reader :handle

        def initialize(label: nil)
          @handle = Object.new
        end

        def release
          @handle = nil
        end

        include WGPU::NativeResource
      end

      LeakyResource.new(label: "orphan")
    RUBY
  end
  let(:adopted_resource_definition) do
    <<~RUBY
      require "wgpu/native_resource"

      class AdoptedResource
        attr_reader :handle

        def self.from_handle(handle, label: nil)
          adopt_native_handle(handle, label: label)
        end

        def release
          @handle = nil
        end

        include WGPU::NativeResource
      end
    RUBY
  end

  it "warns with class and label when enabled" do
    _stdout, stderr, status = Open3.capture3(
      { "WGPU_DEBUG_LEAKS" => "1" },
      RbConfig.ruby,
      "-I",
      library_path,
      "-e",
      script
    )

    expect(status).to be_success
    expect(stderr).to include("WGPU resource leaked: LeakyResource label=\"orphan\"")
  end

  it "is silent by default" do
    _stdout, stderr, status = Open3.capture3(
      { "WGPU_DEBUG_LEAKS" => nil },
      RbConfig.ruby,
      "-I",
      library_path,
      "-e",
      script
    )

    expect(status).to be_success
    expect(stderr).not_to include("WGPU resource leaked")
  end

  it "warns with class and label for an unreleased adopted handle" do
    adopted_script = <<~RUBY
      #{adopted_resource_definition}
      AdoptedResource.from_handle(Object.new, label: "adopted")
    RUBY

    _stdout, stderr, status = Open3.capture3(
      { "WGPU_DEBUG_LEAKS" => "1" },
      RbConfig.ruby,
      "-I",
      library_path,
      "-e",
      adopted_script
    )

    expect(status).to be_success
    expect(stderr).to include("WGPU resource leaked: AdoptedResource label=\"adopted\"")
  end

  it "is silent for a released adopted handle when enabled" do
    adopted_script = <<~RUBY
      #{adopted_resource_definition}
      resource = AdoptedResource.from_handle(Object.new, label: "released")
      resource.release
    RUBY

    _stdout, stderr, status = Open3.capture3(
      { "WGPU_DEBUG_LEAKS" => "1" },
      RbConfig.ruby,
      "-I",
      library_path,
      "-e",
      adopted_script
    )

    expect(status).to be_success
    expect(stderr).not_to include("WGPU resource leaked")
  end
end
