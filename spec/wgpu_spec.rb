# frozen_string_literal: true

RSpec.describe WGPU do
  describe "library loading", :skip_gpu_check do
    it "has a version number" do
      expect(WGPU::VERSION).not_to be_nil
    end

    it "loads the native library" do
      expect(WGPU::Native).to be_a(Module)
    end

    it "defines core classes" do
      expect(defined?(WGPU::Instance)).to eq("constant")
      expect(defined?(WGPU::Adapter)).to eq("constant")
      expect(defined?(WGPU::Device)).to eq("constant")
      expect(defined?(WGPU::Queue)).to eq("constant")
    end

    it "defines resource classes" do
      expect(defined?(WGPU::Buffer)).to eq("constant")
      expect(defined?(WGPU::Texture)).to eq("constant")
      expect(defined?(WGPU::Sampler)).to eq("constant")
    end

    it "defines pipeline classes" do
      expect(defined?(WGPU::ShaderModule)).to eq("constant")
      expect(defined?(WGPU::ComputePipeline)).to eq("constant")
      expect(defined?(WGPU::RenderPipeline)).to eq("constant")
    end
  end

  describe "GPU operations", :gpu do
    it "creates an instance" do
      instance = WGPU::Instance.new
      expect(instance.handle).not_to be_null
      instance.release
    end

    it "requests an adapter" do
      instance = WGPU::Instance.new
      adapter = instance.request_adapter
      expect(adapter).to be_a(WGPU::Adapter)
      expect(adapter.handle).not_to be_null
      adapter.release
      instance.release
    end

    it "requests a device" do
      instance = WGPU::Instance.new
      adapter = instance.request_adapter
      device = adapter.request_device
      expect(device).to be_a(WGPU::Device)
      expect(device.handle).not_to be_null
      device.release
      adapter.release
      instance.release
    end
  end
end
