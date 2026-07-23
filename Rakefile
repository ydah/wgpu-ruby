# frozen_string_literal: true

require "bundler/gem_tasks"
require "fileutils"
require "rspec/core/rake_task"
require_relative "lib/wgpu/native/installer"

RSpec::Core::RakeTask.new(:spec)

namespace :wgpu do
  desc "Download and verify the pinned wgpu-native artifact"
  task :install do
    WGPU::Native::Installer.new.install
  end

  desc "Remove the current wgpu-native cache directory"
  task :clean do
    path = WGPU::Native::Installer.new.clean_path
    unless File.basename(path) == WGPU::Native::Distribution::VERSION
      raise "Refusing to remove unexpected cache path: #{path}"
    end

    FileUtils.rm_rf(path)
    puts "Removed #{path}"
  end

  desc "Compare Ruby enum definitions with the pinned wgpu-native webgpu.h"
  task verify_abi: :install do
    require_relative "lib/wgpu"
    WGPU::Native::AbiVerifier.new.verify!
    puts "wgpu-native #{WGPU::Native::Distribution::VERSION} enum ABI verified"
  end
end

namespace :examples do
  desc "Run compute examples suitable for headless CI"
  task :ci do
    Rake::FileList["examples/0[1-6]_*.rb"].sort.each do |example|
      sh RbConfig.ruby, example
    end
  end
end

task default: :spec
