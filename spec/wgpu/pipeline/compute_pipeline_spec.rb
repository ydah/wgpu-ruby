# frozen_string_literal: true

RSpec.describe WGPU::ComputePipeline, :gpu do
  let(:instance) { WGPU::Instance.new }
  let(:adapter) { instance.request_adapter }
  let(:device) { adapter.request_device }

  after do
    device.release
    adapter.release
    instance.release
  end

  describe "#initialize" do
    it "creates a compute pipeline" do
      shader = device.create_shader_module(code: <<~WGSL)
        @compute @workgroup_size(1)
        fn main() {}
      WGSL
      layout = device.create_pipeline_layout(bind_group_layouts: [])
      pipeline = device.create_compute_pipeline(
        layout: layout,
        compute: { module: shader, entry_point: "main" }
      )
      expect(pipeline).to be_a(WGPU::ComputePipeline)
      expect(pipeline.handle).not_to be_null

      pipeline.release
      layout.release
      shader.release
    end

    it "creates a compute pipeline with label" do
      shader = device.create_shader_module(code: "@compute @workgroup_size(1) fn main() {}")
      layout = device.create_pipeline_layout(bind_group_layouts: [])
      pipeline = device.create_compute_pipeline(
        label: "test pipeline",
        layout: layout,
        compute: { module: shader, entry_point: "main" }
      )
      expect(pipeline.handle).not_to be_null

      pipeline.release
      layout.release
      shader.release
    end

    it "creates a compute pipeline with auto layout" do
      shader = device.create_shader_module(code: "@compute @workgroup_size(1) fn main() {}")
      pipeline = device.create_compute_pipeline(
        layout: :auto,
        compute: { module: shader, entry_point: "main" }
      )
      expect(pipeline).to be_a(WGPU::ComputePipeline)

      pipeline.release
      shader.release
    end

    it "selects the sole compute entry point when entry_point is omitted" do
      shader = device.create_shader_module(
        code: "@compute @workgroup_size(1) fn only_compute_entry() {}"
      )
      pipeline = device.create_compute_pipeline(
        layout: :auto,
        compute: { module: shader }
      )

      expect(pipeline.handle).not_to be_null

      pipeline.release
      shader.release
    end

    it "creates a compute pipeline with bind group layout" do
      shader = device.create_shader_module(code: <<~WGSL)
        @group(0) @binding(0) var<storage, read_write> data: array<f32>;

        @compute @workgroup_size(64)
        fn main(@builtin(global_invocation_id) id: vec3<u32>) {
          data[id.x] = data[id.x] * 2.0;
        }
      WGSL
      bind_group_layout = device.create_bind_group_layout(entries: [
        { binding: 0, visibility: :compute, buffer: { type: :storage } }
      ])
      layout = device.create_pipeline_layout(bind_group_layouts: [bind_group_layout])
      pipeline = device.create_compute_pipeline(
        layout: layout,
        compute: { module: shader, entry_point: "main" }
      )
      expect(pipeline).to be_a(WGPU::ComputePipeline)

      pipeline.release
      layout.release
      bind_group_layout.release
      shader.release
    end
  end

  describe "#get_bind_group_layout" do
    it "returns bind group layout at index" do
      shader = device.create_shader_module(code: <<~WGSL)
        @group(0) @binding(0) var<storage, read_write> data: array<f32>;

        @compute @workgroup_size(1)
        fn main() { data[0] = 1.0; }
      WGSL
      bind_group_layout = device.create_bind_group_layout(entries: [
        { binding: 0, visibility: :compute, buffer: { type: :storage } }
      ])
      layout = device.create_pipeline_layout(bind_group_layouts: [bind_group_layout])
      pipeline = device.create_compute_pipeline(
        layout: layout,
        compute: { module: shader, entry_point: "main" }
      )

      retrieved_layout = pipeline.get_bind_group_layout(0)
      expect(retrieved_layout).to be_a(WGPU::BindGroupLayout)

      retrieved_layout.release
      pipeline.release
      layout.release
      bind_group_layout.release
      shader.release
    end
  end

  describe "#release" do
    it "releases the compute pipeline" do
      shader = device.create_shader_module(code: "@compute @workgroup_size(1) fn main() {}")
      layout = device.create_pipeline_layout(bind_group_layouts: [])
      pipeline = device.create_compute_pipeline(
        layout: layout,
        compute: { module: shader, entry_point: "main" }
      )
      pipeline.release
      expect(pipeline.handle).to be_null

      layout.release
      shader.release
    end
  end

  describe "async creation" do
    it "creates compute pipeline asynchronously" do
      shader = device.create_shader_module(code: <<~WGSL)
        override kValue: f32 = 1.0;

        @compute @workgroup_size(1)
        fn main() {
          let _x = kValue;
        }
      WGSL
      layout = device.create_pipeline_layout(bind_group_layouts: [])
      task = device.create_compute_pipeline_async(
        layout: layout,
        compute: { module: shader, entry_point: "main", constants: { kValue: 1.0 } }
      )
      expect(task).to be_a(WGPU::AsyncTask)
      pipeline = task.value
      expect(pipeline).to be_a(WGPU::ComputePipeline)

      pipeline.release
      layout.release
      shader.release
    end

    it "reports invalid compute pipelines through AsyncTask#value" do
      shader = device.create_shader_module(code: "@compute @workgroup_size(1) fn main() {}")
      task = device.create_compute_pipeline_async(
        layout: :auto,
        compute: { module: shader, entry_point: "missing" }
      )

      expect { task.value }.to raise_error(WGPU::PipelineError)

      shader.release
    end
  end
end
