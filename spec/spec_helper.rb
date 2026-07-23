# frozen_string_literal: true

require "wgpu" unless ENV["WGPU_NO_NATIVE"] == "1"

module WGPUTestHelpers
  def self.gpu_available?
    return @gpu_available if defined?(@gpu_available)

    @gpu_available = check_gpu_available
  end

  def self.check_gpu_available
    return false if ENV["WGPU_SKIP_GPU_TESTS"] == "1"

    instance = WGPU::Instance.new
    adapter = instance.request_adapter
    result = !adapter.nil? && !adapter.handle.null?
    adapter&.release
    instance.release
    result
  rescue StandardError
    false
  end

  def self.gpu_examples_selected?
    RSpec.world.filtered_examples.values.flatten.any? { |example| example.metadata[:gpu] }
  end
end

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:suite) do
    if ENV["WGPU_NO_NATIVE"] == "1"
      puts "Native library disabled: running :no_native tests"
    elsif !WGPUTestHelpers.gpu_examples_selected?
      puts "GPU tests excluded: running GPU-independent tests"
    elsif WGPUTestHelpers.gpu_available?
      puts "GPU available: running all tests"
    else
      puts "GPU not available: skipping GPU-dependent tests"
    end
  end

  config.around(:each) do |example|
    requires_gpu = example.metadata[:gpu] && !example.metadata[:skip_gpu_check]
    if requires_gpu && !WGPUTestHelpers.gpu_available?
      skip "GPU not available"
    else
      example.run
    end
  end
end
