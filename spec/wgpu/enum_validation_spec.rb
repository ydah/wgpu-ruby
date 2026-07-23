# frozen_string_literal: true

RSpec.describe "public enum validation", :skip_gpu_check do
  let(:pointer) { FFI::Pointer.new(1) }
  let(:shader) { Struct.new(:handle).new(pointer) }

  cases = {
    "adapter power preference" => lambda do |context|
      instance = Struct.new(:handle).new(context.pointer)
      WGPU::Adapter.request(instance, power_preference: :invalid_value)
    end,
    "buffer usage" => lambda do |_context|
      WGPU::Buffer.new(Object.new, size: 4, usage: :invalid_value)
    end,
    "texture usage" => lambda do |_context|
      WGPU::Texture.new(
        Object.new,
        size: { width: 1 },
        format: :rgba8_unorm,
        usage: :invalid_value
      )
    end,
    "sampler address mode" => lambda do |_context|
      WGPU::Sampler.new(Object.new, address_mode_u: :invalid_value)
    end,
    "query type" => lambda do |_context|
      WGPU::QuerySet.new(Object.new, type: :invalid_value, count: 1)
    end,
    "error filter" => lambda do |context|
      device = WGPU::Device.allocate
      device.instance_variable_set(:@handle, context.pointer)
      device.push_error_scope(:invalid_value)
    end,
    "render pipeline primitive topology" => lambda do |context|
      WGPU::RenderPipeline.new(
        Object.new,
        layout: nil,
        vertex: { module: context.shader },
        primitive: { topology: :invalid_value }
      )
    end,
    "bind group layout visibility flags" => lambda do |_context|
      layout = WGPU::BindGroupLayout.allocate
      layout.send(
        :create_entry,
        binding: 0,
        visibility: :invalid_value,
        buffer: {}
      )
    end
  }

  cases.each do |name, invocation|
    it "raises ArgumentError with candidates for #{name}" do
      expect { instance_exec(self, &invocation) }.to raise_error(
        ArgumentError,
        /invalid_value.*Valid values:/
      )
    end
  end
end
