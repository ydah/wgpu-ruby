# frozen_string_literal: true

RSpec.describe WGPU::RenderPipeline, :gpu do
  let(:instance) { WGPU::Instance.new }
  let(:adapter) { instance.request_adapter }
  let(:device) { adapter.request_device }

  after do
    device.release
    adapter.release
    instance.release
  end

  let(:vertex_shader) do
    device.create_shader_module(code: <<~WGSL)
      override kScale: f32 = 1.0;

      @vertex
      fn vs_main(@builtin(vertex_index) idx: u32) -> @builtin(position) vec4<f32> {
        var positions = array<vec2<f32>, 3>(
          vec2<f32>(0.0, 0.5),
          vec2<f32>(-0.5, -0.5),
          vec2<f32>(0.5, -0.5)
        );
        return vec4<f32>(positions[idx] * kScale, 0.0, 1.0);
      }
    WGSL
  end

  let(:fragment_shader) do
    device.create_shader_module(code: <<~WGSL)
      override kColor: f32 = 1.0;

      @fragment
      fn fs_main() -> @location(0) vec4<f32> {
        return vec4<f32>(kColor, 0.0, 0.0, 1.0);
      }
    WGSL
  end

  describe "#initialize" do
    it "creates a render pipeline" do
      layout = device.create_pipeline_layout(bind_group_layouts: [])
      pipeline = device.create_render_pipeline(
        layout: layout,
        vertex: { module: vertex_shader, entry_point: "vs_main" },
        fragment: {
          module: fragment_shader,
          entry_point: "fs_main",
          targets: [{ format: :rgba8_unorm }]
        }
      )
      expect(pipeline).to be_a(WGPU::RenderPipeline)
      expect(pipeline.handle).not_to be_null

      pipeline.release
      layout.release
      fragment_shader.release
      vertex_shader.release
    end

    it "creates a render pipeline with label" do
      layout = device.create_pipeline_layout(bind_group_layouts: [])
      pipeline = device.create_render_pipeline(
        label: "test render pipeline",
        layout: layout,
        vertex: { module: vertex_shader, entry_point: "vs_main" },
        fragment: {
          module: fragment_shader,
          entry_point: "fs_main",
          targets: [{ format: :rgba8_unorm }]
        }
      )
      expect(pipeline.handle).not_to be_null

      pipeline.release
      layout.release
      fragment_shader.release
      vertex_shader.release
    end

    it "creates a render pipeline with auto layout" do
      pipeline = device.create_render_pipeline(
        layout: :auto,
        vertex: { module: vertex_shader, entry_point: "vs_main" },
        fragment: {
          module: fragment_shader,
          entry_point: "fs_main",
          targets: [{ format: :rgba8_unorm }]
        }
      )
      expect(pipeline).to be_a(WGPU::RenderPipeline)

      pipeline.release
      fragment_shader.release
      vertex_shader.release
    end

    it "creates a render pipeline with primitive settings" do
      layout = device.create_pipeline_layout(bind_group_layouts: [])
      pipeline = device.create_render_pipeline(
        layout: layout,
        vertex: { module: vertex_shader, entry_point: "vs_main" },
        primitive: { topology: :triangle_list, front_face: :ccw, cull_mode: :back },
        fragment: {
          module: fragment_shader,
          entry_point: "fs_main",
          targets: [{ format: :rgba8_unorm }]
        }
      )
      expect(pipeline).to be_a(WGPU::RenderPipeline)

      pipeline.release
      layout.release
      fragment_shader.release
      vertex_shader.release
    end

    it "creates a render pipeline with multisample settings" do
      layout = device.create_pipeline_layout(bind_group_layouts: [])
      pipeline = device.create_render_pipeline(
        layout: layout,
        vertex: { module: vertex_shader, entry_point: "vs_main" },
        multisample: { count: 1, mask: 0xFFFFFFFF, alpha_to_coverage_enabled: false },
        fragment: {
          module: fragment_shader,
          entry_point: "fs_main",
          targets: [{ format: :rgba8_unorm }]
        }
      )
      expect(pipeline).to be_a(WGPU::RenderPipeline)

      pipeline.release
      layout.release
      fragment_shader.release
      vertex_shader.release
    end

    it "creates a render pipeline with depth stencil" do
      depth_shader = device.create_shader_module(code: <<~WGSL)
        @fragment
        fn fs_main() -> @location(0) vec4<f32> {
          return vec4<f32>(0.0, 0.0, 0.0, 1.0);
        }
      WGSL
      layout = device.create_pipeline_layout(bind_group_layouts: [])
      pipeline = device.create_render_pipeline(
        layout: layout,
        vertex: { module: vertex_shader, entry_point: "vs_main" },
        depth_stencil: { format: :depth24_plus, depth_write_enabled: true, depth_compare: :less },
        fragment: {
          module: depth_shader,
          entry_point: "fs_main",
          targets: [{ format: :rgba8_unorm }]
        }
      )
      expect(pipeline).to be_a(WGPU::RenderPipeline)

      pipeline.release
      layout.release
      depth_shader.release
      vertex_shader.release
    end
  end

  describe "#get_bind_group_layout" do
    it "returns bind group layout at index" do
      bind_group_layout = device.create_bind_group_layout(entries: [
        { binding: 0, visibility: :vertex, buffer: { type: :uniform } }
      ])
      layout = device.create_pipeline_layout(bind_group_layouts: [bind_group_layout])
      pipeline = device.create_render_pipeline(
        layout: layout,
        vertex: { module: vertex_shader, entry_point: "vs_main" },
        fragment: {
          module: fragment_shader,
          entry_point: "fs_main",
          targets: [{ format: :rgba8_unorm }]
        }
      )

      retrieved_layout = pipeline.get_bind_group_layout(0)
      expect(retrieved_layout).to be_a(WGPU::BindGroupLayout)

      retrieved_layout.release
      pipeline.release
      layout.release
      bind_group_layout.release
      fragment_shader.release
      vertex_shader.release
    end
  end

  describe "#release" do
    it "releases the render pipeline" do
      layout = device.create_pipeline_layout(bind_group_layouts: [])
      pipeline = device.create_render_pipeline(
        layout: layout,
        vertex: { module: vertex_shader, entry_point: "vs_main" },
        fragment: {
          module: fragment_shader,
          entry_point: "fs_main",
          targets: [{ format: :rgba8_unorm }]
        }
      )
      pipeline.release
      expect(pipeline.handle).to be_null

      layout.release
      fragment_shader.release
      vertex_shader.release
    end
  end

  describe "async creation" do
    it "creates render pipeline asynchronously" do
      layout = device.create_pipeline_layout(bind_group_layouts: [])
      task = device.create_render_pipeline_async(
        layout: layout,
        vertex: { module: vertex_shader, entry_point: "vs_main", constants: { "kScale" => 1.0 } },
        fragment: {
          module: fragment_shader,
          entry_point: "fs_main",
          constants: { "kColor" => 1.0 },
          targets: [{ format: :rgba8_unorm }]
        }
      )
      expect(task).to be_a(WGPU::AsyncTask)
      pipeline = task.value
      expect(pipeline).to be_a(WGPU::RenderPipeline)

      pipeline.release
      layout.release
      fragment_shader.release
      vertex_shader.release
    end
  end
end

RSpec.describe WGPU::PipelineLayout, :gpu do
  let(:instance) { WGPU::Instance.new }
  let(:adapter) { instance.request_adapter }
  let(:device) { adapter.request_device }

  after do
    device.release
    adapter.release
    instance.release
  end

  describe "#initialize" do
    it "creates an empty pipeline layout" do
      layout = device.create_pipeline_layout(bind_group_layouts: [])
      expect(layout).to be_a(WGPU::PipelineLayout)
      expect(layout.handle).not_to be_null
      layout.release
    end

    it "creates a pipeline layout with label" do
      layout = device.create_pipeline_layout(
        label: "test layout",
        bind_group_layouts: []
      )
      expect(layout.handle).not_to be_null
      layout.release
    end

    it "creates a pipeline layout with bind group layouts" do
      bind_group_layout = device.create_bind_group_layout(entries: [
        { binding: 0, visibility: :compute, buffer: { type: :storage } }
      ])
      layout = device.create_pipeline_layout(bind_group_layouts: [bind_group_layout])
      expect(layout).to be_a(WGPU::PipelineLayout)

      layout.release
      bind_group_layout.release
    end

    it "creates a pipeline layout with multiple bind group layouts" do
      layout1 = device.create_bind_group_layout(entries: [
        { binding: 0, visibility: :compute, buffer: { type: :storage } }
      ])
      layout2 = device.create_bind_group_layout(entries: [
        { binding: 0, visibility: :compute, buffer: { type: :uniform } }
      ])
      pipeline_layout = device.create_pipeline_layout(bind_group_layouts: [layout1, layout2])
      expect(pipeline_layout).to be_a(WGPU::PipelineLayout)

      pipeline_layout.release
      layout2.release
      layout1.release
    end
  end

  describe "#release" do
    it "releases the pipeline layout" do
      layout = device.create_pipeline_layout(bind_group_layouts: [])
      layout.release
      expect(layout.handle).to be_null
    end
  end
end
