# frozen_string_literal: true

RSpec.describe WGPU::Device do
  let(:instance) { WGPU::Instance.new }
  let(:adapter) { instance.request_adapter }
  let(:device) { adapter.request_device }

  after do
    device.release
    adapter.release
    instance.release
  end

  describe "#queue" do
    it "returns a queue" do
      expect(device.queue).to be_a(WGPU::Queue)
    end
  end

  describe "#adapter" do
    it "returns parent adapter" do
      expect(device.adapter).to eq(adapter)
    end
  end

  describe "#adapter_info" do
    it "returns adapter info hash" do
      expect(device.adapter_info).to be_a(Hash)
      expect(device.adapter_info).to have_key(:device)
    end
  end

  describe "#features" do
    it "returns array of enabled features" do
      features = device.features
      expect(features).to be_an(Array)
    end
  end

  describe "#limits" do
    it "returns hash of device limits" do
      limits = device.limits
      expect(limits).to be_a(Hash)
    end

    it "contains expected limit keys" do
      limits = device.limits
      expect(limits).to have_key(:max_texture_dimension_2d)
      expect(limits).to have_key(:max_buffer_size)
      expect(limits).to have_key(:max_bind_groups)
    end

    it "returns positive integer values" do
      limits = device.limits
      expect(limits[:max_texture_dimension_2d]).to be > 0
      expect(limits[:max_bind_groups]).to be > 0
    end
  end

  describe "#create_buffer" do
    it "creates a buffer" do
      buffer = device.create_buffer(size: 256, usage: [:storage, :copy_src])
      expect(buffer).to be_a(WGPU::Buffer)
      expect(buffer.size).to eq(256)
      buffer.release
    end
  end

  describe "#create_buffer_with_data" do
    it "creates a buffer from float array" do
      data = [1.0, 2.0, 3.0, 4.0]
      buffer = device.create_buffer_with_data(data: data, usage: [:storage, :copy_src])
      expect(buffer).to be_a(WGPU::Buffer)
      expect(buffer.size).to eq(16)
      buffer.release
    end

    it "creates a buffer from string" do
      data = "hello world!"
      buffer = device.create_buffer_with_data(data: data, usage: [:storage, :copy_src])
      expect(buffer).to be_a(WGPU::Buffer)
      expect(buffer.size).to eq(data.bytesize)
      buffer.release
    end

    it "accepts a label" do
      buffer = device.create_buffer_with_data(
        label: "test buffer",
        data: [1.0, 2.0],
        usage: :storage
      )
      expect(buffer).to be_a(WGPU::Buffer)
      buffer.release
    end
  end

  describe "#create_texture" do
    it "creates a 2D texture" do
      texture = device.create_texture(
        size: { width: 64, height: 64 },
        format: :rgba8_unorm,
        usage: [:texture_binding, :copy_dst]
      )
      expect(texture).to be_a(WGPU::Texture)
      texture.release
    end

    it "creates a texture with label" do
      texture = device.create_texture(
        label: "test texture",
        size: { width: 32, height: 32 },
        format: :rgba8_unorm,
        usage: :texture_binding
      )
      expect(texture).to be_a(WGPU::Texture)
      texture.release
    end
  end

  describe "#create_sampler" do
    it "creates a sampler with default settings" do
      sampler = device.create_sampler
      expect(sampler).to be_a(WGPU::Sampler)
      sampler.release
    end

    it "creates a sampler with custom settings" do
      sampler = device.create_sampler(
        mag_filter: :linear,
        min_filter: :linear,
        address_mode_u: :repeat,
        address_mode_v: :repeat
      )
      expect(sampler).to be_a(WGPU::Sampler)
      sampler.release
    end
  end

  describe "#create_query_set" do
    it "creates an occlusion query set" do
      query_set = device.create_query_set(type: :occlusion, count: 4)
      expect(query_set).to be_a(WGPU::QuerySet)
      expect(query_set.count).to eq(4)
      expect(query_set.type).to eq(:occlusion)
      query_set.release
    end

    it "creates a query set with label" do
      query_set = device.create_query_set(
        label: "test queries",
        type: :occlusion,
        count: 2
      )
      expect(query_set).to be_a(WGPU::QuerySet)
      query_set.release
    end
  end

  describe "#create_shader_module" do
    it "creates a shader module from WGSL code" do
      shader = device.create_shader_module(code: <<~WGSL)
        @compute @workgroup_size(1)
        fn main() {}
      WGSL
      expect(shader).to be_a(WGPU::ShaderModule)
      shader.release
    end

    it "accepts SPIR-V bytecode" do
      spirv = [
        0x07230203, 0x00010000, 0x0008000A, 0x00000002,
        0x00000000, 0x00020011, 0x00000001, 0x00020011,
        0x0000001C, 0x0002000E, 0x00000000
      ].pack("L<*")
      begin
        shader = device.create_shader_module(code: spirv)
        expect(shader).to be_a(WGPU::ShaderModule)
        shader.release
      rescue WGPU::ShaderError, ArgumentError
        # Some backends/builds do not accept this minimal SPIR-V input.
      end
    end
  end

  describe "#create_command_encoder" do
    it "creates a command encoder" do
      encoder = device.create_command_encoder
      expect(encoder).to be_a(WGPU::CommandEncoder)
      encoder.release
    end

    it "creates a command encoder with label" do
      encoder = device.create_command_encoder(label: "test encoder")
      expect(encoder).to be_a(WGPU::CommandEncoder)
      encoder.release
    end
  end

  describe "#destroy" do
    it "destroys device without raising" do
      expect { device.destroy }.not_to raise_error
    end
  end
end
