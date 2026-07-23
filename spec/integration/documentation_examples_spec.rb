# frozen_string_literal: true

require "open3"
require "rbconfig"
require "tempfile"

RSpec.describe "documentation examples", :gpu do
  it "executes the compute getting-started example" do
    guide = File.expand_path("../../docs/getting_started_compute.md", __dir__)
    markdown = File.read(guide)
    code = markdown.match(/```ruby\n(.+?)\n```/m)&.captures&.first
    raise "Ruby code block missing from #{guide}" unless code

    Tempfile.create(["wgpu-doc-example", ".rb"]) do |file|
      file.write(code)
      file.flush

      stdout, stderr, status = Open3.capture3(
        RbConfig.ruby,
        "-I#{File.expand_path("../../lib", __dir__)}",
        file.path
      )

      expect(status).to be_success, stderr
      expect(stdout).to include("[2, 4, 6, 8]")
    end
  end
end
