#!/usr/bin/env ruby
# frozen_string_literal: true

# Example 08: Colored Quad with Vertex Buffer
# Demonstrates vertex buffers, index buffers, and vertex attributes.
# APIs: vertex/index buffers, render pipeline/pass, RenderPass#draw_indexed.
# Expected: a colored quad is visible until the window is closed.
#
# Requirements:
#   - SDL3 library installed (brew install sdl3 on macOS)
#   - sdl3 gem

require_relative "rendering_example_helper"

SHADER_CODE = File.read(File.expand_path("shaders/colored_quad.wgsl", __dir__))

WIDTH = 800
HEIGHT = 600

puts "=== Colored Quad Example ==="

# Initialize rendering (SDL3 window + WebGPU surface/device)
render = ExampleRendering.setup(
  title: "08 - Colored Quad",
  width: WIDTH,
  height: HEIGHT
)
window = render.window
surface = render.surface
device = render.device
queue = render.queue
format = render.format

# Vertex data: position (vec2) + color (vec3) = 5 floats per vertex
# Layout: x, y, r, g, b
vertices = [
  # Position      # Color
  -0.5, -0.5,     1.0, 0.0, 0.0,  # bottom-left  - red
   0.5, -0.5,     0.0, 1.0, 0.0,  # bottom-right - green
   0.5,  0.5,     0.0, 0.0, 1.0,  # top-right    - blue
  -0.5,  0.5,     1.0, 1.0, 0.0   # top-left     - yellow
]

# Indices for two triangles forming a quad
indices = [
  0, 1, 2,  # first triangle
  0, 2, 3   # second triangle
]

# Create vertex buffer
vertex_data = vertices.pack("f*")
vertex_buffer = device.create_buffer(
  label: "vertex buffer",
  size: vertex_data.bytesize,
  usage: [:vertex, :copy_dst]
)
queue.write_buffer(vertex_buffer, 0, vertex_data)

# Create index buffer
index_data = indices.pack("S*")  # unsigned 16-bit integers
index_buffer = device.create_buffer(
  label: "index buffer",
  size: index_data.bytesize,
  usage: [:index, :copy_dst]
)
queue.write_buffer(index_buffer, 0, index_data)

# Create shader module
shader = device.create_shader_module(label: "quad shader", code: SHADER_CODE)

# Create render pipeline with vertex buffer layout
pipeline_layout = device.create_pipeline_layout(bind_group_layouts: [])
render_pipeline = device.create_render_pipeline(
  label: "quad pipeline",
  layout: pipeline_layout,
  vertex: {
    module: shader,
    entry_point: "vs_main",
    buffers: [{
      array_stride: 5 * 4,  # 5 floats * 4 bytes
      step_mode: :vertex,
      attributes: [
        { format: :float32x2, offset: 0,     shader_location: 0 },  # position
        { format: :float32x3, offset: 2 * 4, shader_location: 1 }   # color
      ]
    }]
  },
  fragment: {
    module: shader,
    entry_point: "fs_main",
    targets: [{ format: format }]
  },
  primitive: {
    topology: :triangle_list
  }
)

puts "Rendering colored quad... (Press Escape or close window to exit)"

# Main render loop
running = true
frame_count = 0

while running
  # Poll events
  events = window.poll_events

  # Check for quit or escape
  if window.should_close?(events) || window.key_pressed?(events, :escape)
    running = false
  end

  next unless running

  texture = nil
  view = nil
  encoder = nil
  pass = nil
  command_buffer = nil

  begin
    # Get current texture from surface
    texture = ExampleRendering.acquire_surface_texture(render)
    next unless texture

    view = texture.create_view

    # Create command encoder
    encoder = device.create_command_encoder(label: "render encoder")

    # Begin render pass
    pass = encoder.begin_render_pass(
      label: "main pass",
      color_attachments: [{
        view: view,
        load_op: :clear,
        store_op: :store,
        clear_value: { r: 0.1, g: 0.1, b: 0.1, a: 1.0 }
      }]
    )

    # Draw quad
    pass.set_pipeline(render_pipeline)
    pass.set_vertex_buffer(0, vertex_buffer)
    pass.set_index_buffer(index_buffer, :uint16)
    pass.draw_indexed(6)  # 6 indices = 2 triangles
    pass.end_pass

    # Submit and present
    command_buffer = encoder.finish
    queue.submit([command_buffer])
    surface.present

    frame_count += 1
  ensure
    command_buffer&.release
    pass&.release
    encoder&.release
    view&.release
    texture&.release
  end
end

puts "Rendered #{frame_count} frames"

# Cleanup
vertex_buffer.release
index_buffer.release
render_pipeline.release
pipeline_layout.release
shader.release
ExampleRendering.cleanup(render)

puts "Done!"
