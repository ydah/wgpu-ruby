# frozen_string_literal: true

RSpec.describe WGPU::RenderPass, :gpu do
  let(:instance) { WGPU::Instance.new }
  let(:adapter) { instance.request_adapter }
  let(:device) { adapter.request_device }

  after do
    device.release
    adapter.release
    instance.release
  end

  let(:render_texture) do
    device.create_texture(
      size: { width: 64, height: 64 },
      format: :rgba8_unorm,
      usage: :render_attachment
    )
  end

  let(:render_view) { render_texture.create_view }

  let(:vertex_shader) do
    device.create_shader_module(code: <<~WGSL)
      @vertex
      fn vs_main(@builtin(vertex_index) idx: u32) -> @builtin(position) vec4<f32> {
        var positions = array<vec2<f32>, 3>(
          vec2<f32>(0.0, 0.5),
          vec2<f32>(-0.5, -0.5),
          vec2<f32>(0.5, -0.5)
        );
        return vec4<f32>(positions[idx], 0.0, 1.0);
      }
    WGSL
  end

  let(:fragment_shader) do
    device.create_shader_module(code: <<~WGSL)
      @fragment
      fn fs_main() -> @location(0) vec4<f32> {
        return vec4<f32>(1.0, 0.0, 0.0, 1.0);
      }
    WGSL
  end

  let(:pipeline_layout) do
    device.create_pipeline_layout(bind_group_layouts: [])
  end

  let(:render_pipeline) do
    device.create_render_pipeline(
      layout: pipeline_layout,
      vertex: { module: vertex_shader, entry_point: "vs_main" },
      fragment: {
        module: fragment_shader,
        entry_point: "fs_main",
        targets: [{ format: :rgba8_unorm }]
      }
    )
  end

  describe "#initialize" do
    it "creates a render pass" do
      encoder = device.create_command_encoder
      pass = encoder.begin_render_pass(
        color_attachments: [{
          view: render_view,
          load_op: :clear,
          store_op: :store,
          clear_value: { r: 0.0, g: 0.0, b: 0.0, a: 1.0 }
        }]
      )
      expect(pass).to be_a(WGPU::RenderPass)
      expect(pass.handle).not_to be_null

      pass.end_pass
      pass.release
      encoder.release
      render_view.release
      render_texture.release
    end

    it "creates a render pass with label" do
      encoder = device.create_command_encoder
      pass = encoder.begin_render_pass(
        label: "test render pass",
        color_attachments: [{
          view: render_view,
          load_op: :clear,
          store_op: :store
        }]
      )
      expect(pass.handle).not_to be_null

      pass.end_pass
      pass.release
      encoder.release
      render_view.release
      render_texture.release
    end

    it "creates a render pass with custom clear color" do
      encoder = device.create_command_encoder
      pass = encoder.begin_render_pass(
        color_attachments: [{
          view: render_view,
          load_op: :clear,
          store_op: :store,
          clear_value: { r: 0.1, g: 0.2, b: 0.3, a: 1.0 }
        }]
      )
      expect(pass).to be_a(WGPU::RenderPass)

      pass.end_pass
      pass.release
      encoder.release
      render_view.release
      render_texture.release
    end

    it "creates a render pass with load op :load" do
      encoder = device.create_command_encoder
      pass = encoder.begin_render_pass(
        color_attachments: [{
          view: render_view,
          load_op: :load,
          store_op: :store
        }]
      )
      expect(pass).to be_a(WGPU::RenderPass)

      pass.end_pass
      pass.release
      encoder.release
      render_view.release
      render_texture.release
    end
  end

  describe "#set_pipeline" do
    it "sets the render pipeline" do
      encoder = device.create_command_encoder
      pass = encoder.begin_render_pass(
        color_attachments: [{
          view: render_view,
          load_op: :clear,
          store_op: :store
        }]
      )

      expect { pass.set_pipeline(render_pipeline) }.not_to raise_error

      pass.end_pass
      pass.release
      encoder.release
      render_pipeline.release
      pipeline_layout.release
      fragment_shader.release
      vertex_shader.release
      render_view.release
      render_texture.release
    end
  end

  describe "#draw" do
    it "draws vertices" do
      encoder = device.create_command_encoder
      pass = encoder.begin_render_pass(
        color_attachments: [{
          view: render_view,
          load_op: :clear,
          store_op: :store
        }]
      )
      pass.set_pipeline(render_pipeline)

      expect { pass.draw(3) }.not_to raise_error

      pass.end_pass
      pass.release
      encoder.release
      render_pipeline.release
      pipeline_layout.release
      fragment_shader.release
      vertex_shader.release
      render_view.release
      render_texture.release
    end

    it "draws vertices with instance count" do
      encoder = device.create_command_encoder
      pass = encoder.begin_render_pass(
        color_attachments: [{
          view: render_view,
          load_op: :clear,
          store_op: :store
        }]
      )
      pass.set_pipeline(render_pipeline)

      expect { pass.draw(3, instance_count: 2) }.not_to raise_error

      pass.end_pass
      pass.release
      encoder.release
      render_pipeline.release
      pipeline_layout.release
      fragment_shader.release
      vertex_shader.release
      render_view.release
      render_texture.release
    end

    it "draws vertices with offset parameters" do
      encoder = device.create_command_encoder
      pass = encoder.begin_render_pass(
        color_attachments: [{
          view: render_view,
          load_op: :clear,
          store_op: :store
        }]
      )
      pass.set_pipeline(render_pipeline)

      expect { pass.draw(3, instance_count: 1, first_vertex: 0, first_instance: 0) }.not_to raise_error

      pass.end_pass
      pass.release
      encoder.release
      render_pipeline.release
      pipeline_layout.release
      fragment_shader.release
      vertex_shader.release
      render_view.release
      render_texture.release
    end
  end

  describe "#set_viewport" do
    it "sets the viewport" do
      encoder = device.create_command_encoder
      pass = encoder.begin_render_pass(
        color_attachments: [{
          view: render_view,
          load_op: :clear,
          store_op: :store
        }]
      )

      expect { pass.set_viewport(0, 0, 64, 64) }.not_to raise_error

      pass.end_pass
      pass.release
      encoder.release
      render_view.release
      render_texture.release
    end

    it "sets the viewport with depth range" do
      encoder = device.create_command_encoder
      pass = encoder.begin_render_pass(
        color_attachments: [{
          view: render_view,
          load_op: :clear,
          store_op: :store
        }]
      )

      expect { pass.set_viewport(0, 0, 64, 64, min_depth: 0.0, max_depth: 1.0) }.not_to raise_error

      pass.end_pass
      pass.release
      encoder.release
      render_view.release
      render_texture.release
    end
  end

  describe "#set_scissor_rect" do
    it "sets the scissor rectangle" do
      encoder = device.create_command_encoder
      pass = encoder.begin_render_pass(
        color_attachments: [{
          view: render_view,
          load_op: :clear,
          store_op: :store
        }]
      )

      expect { pass.set_scissor_rect(0, 0, 32, 32) }.not_to raise_error

      pass.end_pass
      pass.release
      encoder.release
      render_view.release
      render_texture.release
    end
  end

  describe "#end_pass" do
    it "ends the render pass" do
      encoder = device.create_command_encoder
      pass = encoder.begin_render_pass(
        color_attachments: [{
          view: render_view,
          load_op: :clear,
          store_op: :store
        }]
      )

      expect { pass.end_pass }.not_to raise_error

      pass.release
      encoder.release
      render_view.release
      render_texture.release
    end
  end

  describe "#release" do
    it "releases the render pass" do
      encoder = device.create_command_encoder
      pass = encoder.begin_render_pass(
        color_attachments: [{
          view: render_view,
          load_op: :clear,
          store_op: :store
        }]
      )
      pass.end_pass
      pass.release

      expect(pass.handle).to be_null

      encoder.release
      render_view.release
      render_texture.release
    end
  end

  describe "depth stencil attachment" do
    it "creates a render pass with depth stencil attachment" do
      depth_texture = device.create_texture(
        size: { width: 64, height: 64 },
        format: :depth24_plus,
        usage: :render_attachment
      )
      depth_view = depth_texture.create_view

      encoder = device.create_command_encoder
      pass = encoder.begin_render_pass(
        color_attachments: [{
          view: render_view,
          load_op: :clear,
          store_op: :store
        }],
        depth_stencil_attachment: {
          view: depth_view,
          depth_load_op: :clear,
          depth_store_op: :store,
          depth_clear_value: 1.0
        }
      )
      expect(pass).to be_a(WGPU::RenderPass)

      pass.end_pass
      pass.release
      encoder.release
      depth_view.release
      depth_texture.release
      render_view.release
      render_texture.release
    end
  end

  describe "full render workflow" do
    it "executes a complete render pass" do
      encoder = device.create_command_encoder
      pass = encoder.begin_render_pass(
        color_attachments: [{
          view: render_view,
          load_op: :clear,
          store_op: :store,
          clear_value: { r: 0.1, g: 0.2, b: 0.3, a: 1.0 }
        }]
      )
      pass.set_pipeline(render_pipeline)
      pass.set_viewport(0, 0, 64, 64)
      pass.set_scissor_rect(0, 0, 64, 64)
      pass.draw(3)
      pass.end_pass

      command_buffer = encoder.finish
      device.queue.submit([command_buffer])

      pass.release
      encoder.release
      render_pipeline.release
      pipeline_layout.release
      fragment_shader.release
      vertex_shader.release
      render_view.release
      render_texture.release
    end
  end
end
