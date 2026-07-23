# frozen_string_literal: true

RSpec.describe WGPU::Adapter, :gpu do
  let(:instance) { WGPU::Instance.new }
  let(:adapter) { instance.request_adapter }

  after do
    adapter.release
    instance.release
  end

  describe "#info" do
    it "returns adapter information" do
      info = adapter.info
      expect(info).to be_a(Hash)
      expect(info).to have_key(:vendor)
      expect(info).to have_key(:device)
      expect(info).to have_key(:backend_type)
      expect(info).to have_key(:adapter_type)
    end
  end

  describe "#name" do
    it "returns device name" do
      expect(adapter.name).to be_a(String)
    end
  end

  describe "#backend_type" do
    it "returns backend type" do
      expect(adapter.backend_type).to be_a(Symbol)
    end
  end

  describe "#features" do
    it "returns array of supported features" do
      features = adapter.features
      expect(features).to be_an(Array)
    end

    it "contains feature symbols when present" do
      features = adapter.features
      skip "No features available" if features.empty?
      features.each do |feature|
        expect(feature).to be_a(Symbol)
      end
    end
  end

  describe "#limits" do
    it "returns hash of limits" do
      limits = adapter.limits
      expect(limits).to be_a(Hash)
    end

    it "contains expected limit keys" do
      limits = adapter.limits
      expect(limits).to have_key(:max_texture_dimension_2d)
      expect(limits).to have_key(:max_buffer_size)
      expect(limits).to have_key(:max_bind_groups)
      expect(limits).to have_key(:max_compute_workgroup_size_x)
    end

    it "returns positive integer values" do
      limits = adapter.limits
      expect(limits[:max_texture_dimension_2d]).to be > 0
      expect(limits[:max_buffer_size]).to be > 0
    end
  end

  describe "#request_device" do
    it "returns a device" do
      device = adapter.request_device
      expect(device).to be_a(WGPU::Device)
      device.release
    end

    it "accepts required_features and required_limits" do
      required_features = adapter.features.take(1)
      required_limits = { max_bind_groups: adapter.limits[:max_bind_groups] }
      device = adapter.request_device(
        required_features: required_features,
        required_limits: required_limits
      )
      expect(device).to be_a(WGPU::Device)
      device.release
    end
  end

  describe "#request_device_async" do
    it "returns async task resolved to device" do
      task = adapter.request_device_async
      expect(task).to be_a(WGPU::AsyncTask)
      device = task.value
      expect(device).to be_a(WGPU::Device)
      device.release
    end
  end

  describe "#summary" do
    it "returns adapter summary string" do
      expect(adapter.summary).to be_a(String)
      expect(adapter.summary).not_to be_empty
    end
  end
end
