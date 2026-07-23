# frozen_string_literal: true

require "open3"
require "rbconfig"
require "tempfile"

RSpec.describe "native loader failures", :no_native do
  it "reports a clear error for a non-library WGPU_LIB_PATH" do
    Tempfile.create("not-wgpu-native") do |file|
      file.write("not a shared library")
      file.flush
      library_path = File.expand_path("../../../lib", __dir__)

      _stdout, stderr, status = Open3.capture3(
        {
          "WGPU_LIB_PATH" => file.path,
          "WGPU_NO_NATIVE" => nil
        },
        RbConfig.ruby,
        "-I#{library_path}",
        "-e",
        'require "wgpu"'
      )

      expect(status).not_to be_success
      expect(stderr).to match(/LoadError|Could not open library|invalid ELF|file too short/i)
      expect(stderr).to include(file.path)
    end
  end
end
