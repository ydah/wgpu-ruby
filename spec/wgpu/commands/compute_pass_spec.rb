# frozen_string_literal: true

RSpec.describe WGPU::ComputePass, :gpu do
  let(:instance) { WGPU::Instance.new }
  let(:adapter) { instance.request_adapter }
  let(:device) { adapter.request_device }

  after do
    device.release
    adapter.release
    instance.release
  end

  let(:shader) do
    device.create_shader_module(code: <<~WGSL)
      @group(0) @binding(0) var<storage, read_write> data: array<f32>;

      @compute @workgroup_size(64)
      fn main(@builtin(global_invocation_id) id: vec3<u32>) {
        data[id.x] = data[id.x] * 2.0;
      }
    WGSL
  end

  let(:bind_group_layout) do
    device.create_bind_group_layout(entries: [
      { binding: 0, visibility: :compute, buffer: { type: :storage } }
    ])
  end

  let(:pipeline_layout) do
    device.create_pipeline_layout(bind_group_layouts: [bind_group_layout])
  end

  let(:pipeline) do
    device.create_compute_pipeline(
      layout: pipeline_layout,
      compute: { module: shader, entry_point: "main" }
    )
  end

  describe "#initialize" do
    it "creates a compute pass" do
      encoder = device.create_command_encoder
      pass = encoder.begin_compute_pass
      expect(pass).to be_a(WGPU::ComputePass)
      expect(pass.handle).not_to be_null

      pass.end_pass
      pass.release
      encoder.release
    end

    it "creates a compute pass with label" do
      encoder = device.create_command_encoder
      pass = encoder.begin_compute_pass(label: "test compute pass")
      expect(pass.handle).not_to be_null

      pass.end_pass
      pass.release
      encoder.release
    end
  end

  describe "#set_pipeline" do
    it "sets the compute pipeline" do
      encoder = device.create_command_encoder
      pass = encoder.begin_compute_pass

      expect { pass.set_pipeline(pipeline) }.not_to raise_error

      pass.end_pass
      pass.release
      encoder.release
      pipeline.release
      pipeline_layout.release
      bind_group_layout.release
      shader.release
    end
  end

  describe "#set_bind_group" do
    it "sets a bind group" do
      buffer = device.create_buffer(size: 256, usage: :storage)
      bind_group = device.create_bind_group(
        layout: bind_group_layout,
        entries: [{ binding: 0, buffer: buffer }]
      )

      encoder = device.create_command_encoder
      pass = encoder.begin_compute_pass
      pass.set_pipeline(pipeline)

      expect { pass.set_bind_group(0, bind_group) }.not_to raise_error

      pass.end_pass
      pass.release
      encoder.release
      bind_group.release
      buffer.release
      pipeline.release
      pipeline_layout.release
      bind_group_layout.release
      shader.release
    end
  end

  describe "#dispatch_workgroups" do
    it "dispatches workgroups" do
      buffer = device.create_buffer(size: 256, usage: :storage)
      bind_group = device.create_bind_group(
        layout: bind_group_layout,
        entries: [{ binding: 0, buffer: buffer }]
      )

      encoder = device.create_command_encoder
      pass = encoder.begin_compute_pass
      pass.set_pipeline(pipeline)
      pass.set_bind_group(0, bind_group)

      expect { pass.dispatch_workgroups(1) }.not_to raise_error

      pass.end_pass
      pass.release
      encoder.release
      bind_group.release
      buffer.release
      pipeline.release
      pipeline_layout.release
      bind_group_layout.release
      shader.release
    end

    it "dispatches workgroups with y and z dimensions" do
      buffer = device.create_buffer(size: 256, usage: :storage)
      bind_group = device.create_bind_group(
        layout: bind_group_layout,
        entries: [{ binding: 0, buffer: buffer }]
      )

      encoder = device.create_command_encoder
      pass = encoder.begin_compute_pass
      pass.set_pipeline(pipeline)
      pass.set_bind_group(0, bind_group)

      expect { pass.dispatch_workgroups(1, 1, 1) }.not_to raise_error

      pass.end_pass
      pass.release
      encoder.release
      bind_group.release
      buffer.release
      pipeline.release
      pipeline_layout.release
      bind_group_layout.release
      shader.release
    end
  end

  describe "#end_pass" do
    it "ends the compute pass" do
      encoder = device.create_command_encoder
      pass = encoder.begin_compute_pass

      expect { pass.end_pass }.not_to raise_error

      pass.release
      encoder.release
    end
  end

  describe "#release" do
    it "releases the compute pass" do
      encoder = device.create_command_encoder
      pass = encoder.begin_compute_pass
      pass.end_pass
      pass.release

      expect(pass.handle).to be_null

      encoder.release
    end

    it "can be called multiple times" do
      encoder = device.create_command_encoder
      pass = encoder.begin_compute_pass
      pass.end_pass
      pass.release

      expect { pass.release }.not_to raise_error

      encoder.release
    end
  end

  describe "full compute workflow" do
    it "executes a complete compute pass" do
      buffer = device.create_buffer(size: 256, usage: :storage)
      bind_group = device.create_bind_group(
        layout: bind_group_layout,
        entries: [{ binding: 0, buffer: buffer }]
      )

      encoder = device.create_command_encoder
      pass = encoder.begin_compute_pass
      pass.set_pipeline(pipeline)
      pass.set_bind_group(0, bind_group)
      pass.dispatch_workgroups(4)
      pass.end_pass

      command_buffer = encoder.finish
      device.queue.submit([command_buffer])

      bind_group.release
      buffer.release
      pipeline.release
      pipeline_layout.release
      bind_group_layout.release
      shader.release
      pass.release
      encoder.release
    end
  end
end
