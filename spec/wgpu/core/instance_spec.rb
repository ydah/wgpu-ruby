# frozen_string_literal: true

RSpec.describe WGPU::Instance, :gpu do
  describe "#initialize" do
    it "creates a valid instance" do
      instance = WGPU::Instance.new
      expect(instance).to be_a(WGPU::Instance)
      expect(instance.handle).not_to be_null
      instance.release
    end

    it "creates multiple instances" do
      instance1 = WGPU::Instance.new
      instance2 = WGPU::Instance.new
      expect(instance1.handle).not_to eq(instance2.handle)
      instance1.release
      instance2.release
    end
  end

  describe "#request_adapter" do
    it "returns an adapter" do
      instance = WGPU::Instance.new
      adapter = instance.request_adapter
      expect(adapter).to be_a(WGPU::Adapter)
      expect(adapter.handle).not_to be_null
      expect(adapter.instance).to eq(instance)
      adapter.release
      instance.release
    end

    it "returns an adapter with high performance preference" do
      instance = WGPU::Instance.new
      adapter = instance.request_adapter(power_preference: :high_performance)
      expect(adapter).to be_a(WGPU::Adapter)
      adapter.release
      instance.release
    end

    it "returns an adapter with low power preference" do
      instance = WGPU::Instance.new
      adapter = instance.request_adapter(power_preference: :low_power)
      expect(adapter).to be_a(WGPU::Adapter)
      adapter.release
      instance.release
    end
  end

  describe "#request_adapter_async" do
    it "returns async task resolved to adapter" do
      instance = WGPU::Instance.new
      task = instance.request_adapter_async
      expect(task).to be_a(WGPU::AsyncTask)
      adapter = task.value
      expect(adapter).to be_a(WGPU::Adapter)
      adapter.release
      instance.release
    end
  end

  describe "#enumerate_adapters_async" do
    it "returns async task resolved to adapter list" do
      instance = WGPU::Instance.new
      task = instance.enumerate_adapters_async
      expect(task).to be_a(WGPU::AsyncTask)
      adapters = task.value
      expect(adapters).to be_an(Array)
      adapters.each(&:release)
      instance.release
    end
  end

  describe "#get_canvas_context" do
    it "returns canvas context wrapper" do
      instance = WGPU::Instance.new
      context = instance.get_canvas_context(surface: Object.new)
      expect(context).to be_a(WGPU::CanvasContext)
      instance.release
    end
  end

  describe "#release" do
    it "releases the instance" do
      instance = WGPU::Instance.new
      instance.release
      expect(instance.handle).to be_null
    end

    it "can be called multiple times" do
      instance = WGPU::Instance.new
      instance.release
      expect { instance.release }.not_to raise_error
    end
  end

  describe "full workflow" do
    it "supports instance -> adapter -> device chain" do
      instance = WGPU::Instance.new
      adapter = instance.request_adapter
      device = adapter.request_device

      expect(device).to be_a(WGPU::Device)
      expect(device.handle).not_to be_null

      device.release
      adapter.release
      instance.release
    end

    it "supports multiple adapters from same instance" do
      instance = WGPU::Instance.new
      adapter1 = instance.request_adapter
      adapter2 = instance.request_adapter

      expect(adapter1).to be_a(WGPU::Adapter)
      expect(adapter2).to be_a(WGPU::Adapter)

      adapter1.release
      adapter2.release
      instance.release
    end
  end
end
