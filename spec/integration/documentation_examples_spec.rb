# frozen_string_literal: true

require "open3"
require "rbconfig"
require "tempfile"

RSpec.describe "documentation examples", :gpu do
  EXAMPLE_PATTERN =
    /<!-- wgpu-example: run; expect: (?<expected>.+?) -->\s*```ruby\n(?<code>.+?)\n```/m

  it "executes every marked Ruby example" do
    root = File.expand_path("../..", __dir__)
    markdown_files = [File.join(root, "README.md"), *Dir[File.join(root, "docs", "*.md")]]
    examples = markdown_files.flat_map do |path|
      File.read(path).scan(EXAMPLE_PATTERN).map do |expected, code|
        [path, expected, code]
      end
    end

    expect(examples).not_to be_empty

    examples.each do |path, expected, code|
      Tempfile.create(["wgpu-doc-example", ".rb"]) do |file|
        file.write(code)
        file.flush

        stdout, stderr, status = Open3.capture3(
          RbConfig.ruby,
          "-I#{File.join(root, "lib")}",
          file.path
        )

        expect(status).to be_success, "#{path} failed:\n#{stderr}"
        expect(stdout).to include(expected), "#{path} did not print #{expected.inspect}"
      end
    end
  end
end
