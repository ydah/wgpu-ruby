# frozen_string_literal: true

RSpec.describe WGPU::ShaderModule, :gpu do
  let(:instance) { WGPU::Instance.new }
  let(:adapter) { instance.request_adapter }
  let(:device) { adapter.request_device }

  after do
    device.release
    adapter.release
    instance.release
  end

  describe "#initialize" do
    it "creates a shader module from WGSL code" do
      shader = device.create_shader_module(code: <<~WGSL)
        @compute @workgroup_size(1)
        fn main() {}
      WGSL
      expect(shader).to be_a(WGPU::ShaderModule)
      expect(shader.handle).not_to be_null
      shader.release
    end

    it "creates a shader module with label" do
      shader = device.create_shader_module(
        label: "test shader",
        code: "@compute @workgroup_size(1) fn main() {}"
      )
      expect(shader.handle).not_to be_null
      shader.release
    end

    it "creates a compute shader module" do
      shader = device.create_shader_module(code: <<~WGSL)
        @group(0) @binding(0) var<storage, read_write> data: array<f32>;

        @compute @workgroup_size(64)
        fn main(@builtin(global_invocation_id) id: vec3<u32>) {
          data[id.x] = data[id.x] * 2.0;
        }
      WGSL
      expect(shader).to be_a(WGPU::ShaderModule)
      shader.release
    end

    it "creates a vertex shader module" do
      shader = device.create_shader_module(code: <<~WGSL)
        @vertex
        fn vs_main(@builtin(vertex_index) idx: u32) -> @builtin(position) vec4<f32> {
          return vec4<f32>(0.0, 0.0, 0.0, 1.0);
        }
      WGSL
      expect(shader).to be_a(WGPU::ShaderModule)
      shader.release
    end

    it "creates a fragment shader module" do
      shader = device.create_shader_module(code: <<~WGSL)
        @fragment
        fn fs_main() -> @location(0) vec4<f32> {
          return vec4<f32>(1.0, 0.0, 0.0, 1.0);
        }
      WGSL
      expect(shader).to be_a(WGPU::ShaderModule)
      shader.release
    end
  end

  describe "#release" do
    it "releases the shader module" do
      shader = device.create_shader_module(code: "@compute @workgroup_size(1) fn main() {}")
      shader.release
      expect(shader.handle).to be_null
    end

    it "can be called multiple times" do
      shader = device.create_shader_module(code: "@compute @workgroup_size(1) fn main() {}")
      shader.release
      expect { shader.release }.not_to raise_error
    end
  end
end
