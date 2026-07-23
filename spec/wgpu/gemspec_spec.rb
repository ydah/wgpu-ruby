# frozen_string_literal: true

require "rubygems"

RSpec.describe "wgpu.gemspec", :no_native do
  subject(:gem_specification) { Gem::Specification.load(gemspec_path) }

  let(:project_root) { File.expand_path("../..", __dir__) }
  let(:gemspec_path) { File.join(project_root, "wgpu.gemspec") }

  it "only lists paths that exist" do
    missing_files = gem_specification.files.reject do |path|
      File.exist?(File.join(project_root, path))
    end

    expect(missing_files).to be_empty
  end

  it "packages the public API, extension, documentation, signatures, and licenses" do
    required_files = %w[
      lib/wgpu.rb
      ext/wgpu/extconf.rb
      docs/README.md
      sig/wgpu.rbs
      README.md
      CHANGELOG.md
      LICENSE-MIT
      LICENSE-APACHE
    ]

    expect(gem_specification.files).to include(*required_files)
  end

  it "packages every maintained library, documentation, and signature file" do
    source_patterns = %w[lib/**/* docs/**/*.md sig/**/*.rbs ext/**/*.rb]
    maintained_files = source_patterns.flat_map do |pattern|
      Dir[File.join(project_root, pattern)]
    end.select { |path| File.file?(path) }
      .map { |path| path.delete_prefix("#{project_root}/") }

    expect(gem_specification.files).to include(*maintained_files)
  end

  it "excludes generated output and temporary files" do
    excluded_path = %r{\A(?:doc|pkg|tmp)(?:/|\z)}

    expect(gem_specification.files).not_to include(a_string_matching(excluded_path))
  end

  it "keeps SDL3 optional" do
    dependencies = gem_specification.runtime_dependencies.to_h do |dependency|
      [dependency.name, dependency.requirement.to_s]
    end

    expect(dependencies).to eq(
      "ffi" => "~> 1.15",
      "rubyzip" => "~> 2.3"
    )
  end

  it "publishes project, source, changelog, and documentation links" do
    expect(gem_specification.metadata).to include(
      "homepage_uri" => "https://github.com/ydah/wgpu-ruby",
      "source_code_uri" => "https://github.com/ydah/wgpu-ruby/tree/main",
      "changelog_uri" => "https://github.com/ydah/wgpu-ruby/blob/main/CHANGELOG.md",
      "documentation_uri" => "https://www.rubydoc.info/gems/wgpu"
    )
  end
end
