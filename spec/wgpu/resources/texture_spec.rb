# frozen_string_literal: true

RSpec.describe WGPU::Texture, :gpu do
  let(:instance) { WGPU::Instance.new }
  let(:adapter) { instance.request_adapter }
  let(:device) { adapter.request_device }

  after do
    device.release
    adapter.release
    instance.release
  end

  describe "#initialize" do
    it "creates a 2D texture" do
      texture = device.create_texture(
        size: { width: 256, height: 256 },
        format: :rgba8_unorm,
        usage: :texture_binding
      )
      expect(texture).to be_a(WGPU::Texture)
      expect(texture.handle).not_to be_null
      texture.release
    end

    it "creates a texture with label" do
      texture = device.create_texture(
        label: "test texture",
        size: { width: 128, height: 128 },
        format: :rgba8_unorm,
        usage: :texture_binding
      )
      expect(texture.handle).not_to be_null
      texture.release
    end

    it "creates a texture with multiple usages" do
      texture = device.create_texture(
        size: { width: 64, height: 64 },
        format: :rgba8_unorm,
        usage: [:texture_binding, :copy_dst, :copy_src]
      )
      expect(texture).to be_a(WGPU::Texture)
      texture.release
    end

    it "creates a texture with mip levels" do
      texture = device.create_texture(
        size: { width: 256, height: 256 },
        format: :rgba8_unorm,
        usage: :texture_binding,
        mip_level_count: 4
      )
      expect(texture).to be_a(WGPU::Texture)
      texture.release
    end

    it "creates a texture with view formats" do
      texture = device.create_texture(
        size: { width: 64, height: 64 },
        format: :rgba8_unorm,
        usage: [:texture_binding, :copy_dst],
        view_formats: [:rgba8_unorm]
      )
      expect(texture).to be_a(WGPU::Texture)
      texture.release
    end

    it "creates a render attachment texture" do
      texture = device.create_texture(
        size: { width: 512, height: 512 },
        format: :rgba8_unorm,
        usage: :render_attachment
      )
      expect(texture).to be_a(WGPU::Texture)
      texture.release
    end

    it "creates a depth texture" do
      texture = device.create_texture(
        size: { width: 256, height: 256 },
        format: :depth24_plus,
        usage: :render_attachment
      )
      expect(texture).to be_a(WGPU::Texture)
      texture.release
    end
  end

  describe "#create_view" do
    it "creates a texture view" do
      texture = device.create_texture(
        size: { width: 64, height: 64 },
        format: :rgba8_unorm,
        usage: :texture_binding
      )
      view = texture.create_view
      expect(view).to be_a(WGPU::TextureView)
      view.release
      texture.release
    end

    it "creates a texture view with label" do
      texture = device.create_texture(
        size: { width: 64, height: 64 },
        format: :rgba8_unorm,
        usage: :texture_binding
      )
      view = texture.create_view(label: "test view")
      expect(view).to be_a(WGPU::TextureView)
      view.release
      texture.release
    end

    it "creates a texture view with restricted usage" do
      texture = device.create_texture(
        size: { width: 64, height: 64 },
        format: :rgba8_unorm,
        usage: [:texture_binding, :render_attachment]
      )
      view = texture.create_view(usage: :texture_binding)
      expect(view).to be_a(WGPU::TextureView)
      view.release
      texture.release
    end
  end

  describe "#width" do
    it "returns the texture width" do
      texture = device.create_texture(
        size: { width: 128, height: 64 },
        format: :rgba8_unorm,
        usage: :texture_binding
      )
      expect(texture.width).to eq(128)
      texture.release
    end
  end

  describe "#height" do
    it "returns the texture height" do
      texture = device.create_texture(
        size: { width: 128, height: 64 },
        format: :rgba8_unorm,
        usage: :texture_binding
      )
      expect(texture.height).to eq(64)
      texture.release
    end
  end

  describe "#format" do
    it "returns the texture format" do
      texture = device.create_texture(
        size: { width: 64, height: 64 },
        format: :rgba8_unorm,
        usage: :texture_binding
      )
      expect(texture.format).to eq(:rgba8_unorm)
      texture.release
    end
  end

  describe "#size" do
    it "returns size hash" do
      texture = device.create_texture(
        size: { width: 32, height: 16, depth_or_array_layers: 1 },
        format: :rgba8_unorm,
        usage: :texture_binding
      )
      expect(texture.size).to eq(width: 32, height: 16, depth_or_array_layers: 1)
      texture.release
    end
  end

  describe "#destroy" do
    it "destroys the texture" do
      texture = device.create_texture(
        size: { width: 64, height: 64 },
        format: :rgba8_unorm,
        usage: :texture_binding
      )
      expect { texture.destroy }.not_to raise_error
    end
  end

  describe "#release" do
    it "releases the texture" do
      texture = device.create_texture(
        size: { width: 64, height: 64 },
        format: :rgba8_unorm,
        usage: :texture_binding
      )
      texture.release
      expect(texture.handle).to be_null
    end
  end
end

RSpec.describe WGPU::TextureView, :gpu do
  let(:instance) { WGPU::Instance.new }
  let(:adapter) { instance.request_adapter }
  let(:device) { adapter.request_device }
  let(:texture) do
    device.create_texture(
      size: { width: 64, height: 64 },
      format: :rgba8_unorm,
      usage: [:texture_binding, :render_attachment]
    )
  end

  after do
    texture.release
    device.release
    adapter.release
    instance.release
  end

  describe "#initialize" do
    it "creates a texture view" do
      view = texture.create_view
      expect(view).to be_a(WGPU::TextureView)
      expect(view.handle).not_to be_null
      expect(view.texture).to eq(texture)
      expect(view.size).to eq(texture.size)
      view.release
    end
  end

  describe "#release" do
    it "releases the texture view" do
      view = texture.create_view
      view.release
      expect(view.handle).to be_null
    end

    it "can be called multiple times" do
      view = texture.create_view
      view.release
      expect { view.release }.not_to raise_error
    end
  end
end
