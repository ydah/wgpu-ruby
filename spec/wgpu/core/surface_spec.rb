# frozen_string_literal: true

RSpec.describe WGPU::Surface do
  let(:instance) { WGPU::Instance.new }

  after do
    instance.release
  end

  describe "class interface" do
    it "responds to from_metal_layer" do
      expect(WGPU::Surface).to respond_to(:from_metal_layer)
    end

    it "responds to from_windows_hwnd" do
      expect(WGPU::Surface).to respond_to(:from_windows_hwnd)
    end

    it "responds to from_xlib_window" do
      expect(WGPU::Surface).to respond_to(:from_xlib_window)
    end

    it "responds to from_wayland_surface" do
      expect(WGPU::Surface).to respond_to(:from_wayland_surface)
    end
  end

  describe "instance methods" do
    it "defines configure method" do
      expect(WGPU::Surface.instance_methods).to include(:configure)
    end

    it "defines unconfigure method" do
      expect(WGPU::Surface.instance_methods).to include(:unconfigure)
    end

    it "defines current_texture method" do
      expect(WGPU::Surface.instance_methods).to include(:current_texture)
    end

    it "defines present method" do
      expect(WGPU::Surface.instance_methods).to include(:present)
    end

    it "defines capabilities method" do
      expect(WGPU::Surface.instance_methods).to include(:capabilities)
    end

    it "defines get_configuration method" do
      expect(WGPU::Surface.instance_methods).to include(:get_configuration)
    end

    it "defines get_preferred_format method" do
      expect(WGPU::Surface.instance_methods).to include(:get_preferred_format)
    end

    it "defines release method" do
      expect(WGPU::Surface.instance_methods).to include(:release)
    end
  end
end
