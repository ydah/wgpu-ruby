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
end
