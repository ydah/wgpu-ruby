# frozen_string_literal: true

RSpec.describe WGPU::Sampler do
  let(:instance) { WGPU::Instance.new }
  let(:adapter) { instance.request_adapter }
  let(:device) { adapter.request_device }

  after do
    device.release
    adapter.release
    instance.release
  end

  describe "#initialize" do
    it "creates a sampler with default settings" do
      sampler = device.create_sampler
      expect(sampler).to be_a(WGPU::Sampler)
      expect(sampler.handle).not_to be_null
      sampler.release
    end

    it "creates a sampler with label" do
      sampler = device.create_sampler(label: "test sampler")
      expect(sampler.handle).not_to be_null
      sampler.release
    end

    it "creates a sampler with linear filtering" do
      sampler = device.create_sampler(
        mag_filter: :linear,
        min_filter: :linear,
        mipmap_filter: :linear
      )
      expect(sampler).to be_a(WGPU::Sampler)
      sampler.release
    end

    it "creates a sampler with nearest filtering" do
      sampler = device.create_sampler(
        mag_filter: :nearest,
        min_filter: :nearest,
        mipmap_filter: :nearest
      )
      expect(sampler).to be_a(WGPU::Sampler)
      sampler.release
    end

    it "creates a sampler with repeat addressing" do
      sampler = device.create_sampler(
        address_mode_u: :repeat,
        address_mode_v: :repeat,
        address_mode_w: :repeat
      )
      expect(sampler).to be_a(WGPU::Sampler)
      sampler.release
    end

    it "creates a sampler with clamp to edge addressing" do
      sampler = device.create_sampler(
        address_mode_u: :clamp_to_edge,
        address_mode_v: :clamp_to_edge,
        address_mode_w: :clamp_to_edge
      )
      expect(sampler).to be_a(WGPU::Sampler)
      sampler.release
    end

    it "creates a sampler with mirror repeat addressing" do
      sampler = device.create_sampler(
        address_mode_u: :mirror_repeat,
        address_mode_v: :mirror_repeat
      )
      expect(sampler).to be_a(WGPU::Sampler)
      sampler.release
    end

    it "creates a sampler with LOD clamp" do
      sampler = device.create_sampler(
        lod_min_clamp: 0.0,
        lod_max_clamp: 10.0
      )
      expect(sampler).to be_a(WGPU::Sampler)
      sampler.release
    end

    it "creates a sampler with anisotropy" do
      sampler = device.create_sampler(
        max_anisotropy: 4,
        mag_filter: :linear,
        min_filter: :linear,
        mipmap_filter: :linear
      )
      expect(sampler).to be_a(WGPU::Sampler)
      sampler.release
    end

    it "creates a comparison sampler" do
      sampler = device.create_sampler(compare: :less)
      expect(sampler).to be_a(WGPU::Sampler)
      sampler.release
    end
  end

  describe "#release" do
    it "releases the sampler" do
      sampler = device.create_sampler
      sampler.release
      expect(sampler.handle).to be_null
    end

    it "can be called multiple times" do
      sampler = device.create_sampler
      sampler.release
      expect { sampler.release }.not_to raise_error
    end
  end
end
