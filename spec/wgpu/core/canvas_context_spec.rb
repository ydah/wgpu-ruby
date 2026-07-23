# frozen_string_literal: true

RSpec.describe WGPU::CanvasContext, :gpu do
  class FakeSurface
    attr_reader :configured

    def initialize
      @configured = nil
    end

    def configure(**kwargs)
      @configured = kwargs
    end

    def unconfigure
      @configured = nil
    end

    def current_texture
      :fake_texture
    end

    def present
      true
    end

    def get_preferred_format(_adapter)
      :bgra8_unorm
    end
  end

  let(:instance) { WGPU::Instance.new }
  let(:adapter) { instance.request_adapter }
  let(:device) { adapter.request_device }
  let(:surface) { FakeSurface.new }
  let(:context) { described_class.new(instance, surface: surface) }

  after do
    device.release
    adapter.release
    instance.release
  end

  describe "#set_physical_size" do
    it "stores physical size" do
      context.set_physical_size(640, 480)
      expect(context.physical_size).to eq([640, 480])
    end
  end

  describe "#configure" do
    it "stores configuration and delegates to surface" do
      context.configure(device: device, width: 640, height: 480)
      expect(context.get_configuration).to be_a(Hash)
      expect(surface.configured[:width]).to eq(640)
      expect(surface.configured[:height]).to eq(480)
    end
  end

  describe "#get_current_texture" do
    it "returns current texture after configure" do
      context.configure(device: device, width: 64, height: 64)
      expect(context.get_current_texture).to eq(:fake_texture)
    end
  end
end
