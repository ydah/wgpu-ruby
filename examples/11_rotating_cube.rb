#!/usr/bin/env ruby
# frozen_string_literal: true

# Example 11: Rotating 3D Cube
# Demonstrates 3D rendering with depth buffer, uniform buffers, and matrix transformations.
#
# Requirements:
#   - SDL3 library installed (brew install sdl3 on macOS)
#   - sdl3 gem

require_relative "rendering_example_helper"

SHADER_CODE = File.read(File.expand_path("shaders/rotating_cube.wgsl", __dir__))

WIDTH = 800
HEIGHT = 600

# Simple matrix math helpers
module MatrixMath
  def self.identity
    [
      1.0, 0.0, 0.0, 0.0,
      0.0, 1.0, 0.0, 0.0,
      0.0, 0.0, 1.0, 0.0,
      0.0, 0.0, 0.0, 1.0
    ]
  end

  def self.perspective(fov_y, aspect, near, far)
    f = 1.0 / Math.tan(fov_y / 2.0)
    nf = 1.0 / (near - far)

    [
      f / aspect, 0.0, 0.0, 0.0,
      0.0, f, 0.0, 0.0,
      0.0, 0.0, (far + near) * nf, -1.0,
      0.0, 0.0, 2.0 * far * near * nf, 0.0
    ]
  end

  def self.translate(x, y, z)
    [
      1.0, 0.0, 0.0, 0.0,
      0.0, 1.0, 0.0, 0.0,
      0.0, 0.0, 1.0, 0.0,
      x, y, z, 1.0
    ]
  end

  def self.rotate_x(angle)
    c = Math.cos(angle)
    s = Math.sin(angle)
    [
      1.0, 0.0, 0.0, 0.0,
      0.0, c, s, 0.0,
      0.0, -s, c, 0.0,
      0.0, 0.0, 0.0, 1.0
    ]
  end

  def self.rotate_y(angle)
    c = Math.cos(angle)
    s = Math.sin(angle)
    [
      c, 0.0, -s, 0.0,
      0.0, 1.0, 0.0, 0.0,
      s, 0.0, c, 0.0,
      0.0, 0.0, 0.0, 1.0
    ]
  end

  def self.multiply(a, b)
    result = Array.new(16, 0.0)
    4.times do |row|
      4.times do |col|
        sum = 0.0
        4.times do |k|
          sum += a[row + k * 4] * b[k + col * 4]
        end
        result[row + col * 4] = sum
      end
    end
    result
  end
end

# Cube vertex data: position (vec3) + color (vec3)
CUBE_VERTICES = [
  # Front face (red)
  -1.0, -1.0,  1.0,   1.0, 0.0, 0.0,
   1.0, -1.0,  1.0,   1.0, 0.0, 0.0,
   1.0,  1.0,  1.0,   1.0, 0.0, 0.0,
  -1.0,  1.0,  1.0,   1.0, 0.0, 0.0,
  # Back face (green)
  -1.0, -1.0, -1.0,   0.0, 1.0, 0.0,
  -1.0,  1.0, -1.0,   0.0, 1.0, 0.0,
   1.0,  1.0, -1.0,   0.0, 1.0, 0.0,
   1.0, -1.0, -1.0,   0.0, 1.0, 0.0,
  # Top face (blue)
  -1.0,  1.0, -1.0,   0.0, 0.0, 1.0,
  -1.0,  1.0,  1.0,   0.0, 0.0, 1.0,
   1.0,  1.0,  1.0,   0.0, 0.0, 1.0,
   1.0,  1.0, -1.0,   0.0, 0.0, 1.0,
  # Bottom face (yellow)
  -1.0, -1.0, -1.0,   1.0, 1.0, 0.0,
   1.0, -1.0, -1.0,   1.0, 1.0, 0.0,
   1.0, -1.0,  1.0,   1.0, 1.0, 0.0,
  -1.0, -1.0,  1.0,   1.0, 1.0, 0.0,
  # Right face (magenta)
   1.0, -1.0, -1.0,   1.0, 0.0, 1.0,
   1.0,  1.0, -1.0,   1.0, 0.0, 1.0,
   1.0,  1.0,  1.0,   1.0, 0.0, 1.0,
   1.0, -1.0,  1.0,   1.0, 0.0, 1.0,
  # Left face (cyan)
  -1.0, -1.0, -1.0,   0.0, 1.0, 1.0,
  -1.0, -1.0,  1.0,   0.0, 1.0, 1.0,
  -1.0,  1.0,  1.0,   0.0, 1.0, 1.0,
  -1.0,  1.0, -1.0,   0.0, 1.0, 1.0
].freeze

CUBE_INDICES = [
  0,  1,  2,   0,  2,  3,   # front
  4,  5,  6,   4,  6,  7,   # back
  8,  9,  10,  8,  10, 11,  # top
  12, 13, 14,  12, 14, 15,  # bottom
  16, 17, 18,  16, 18, 19,  # right
  20, 21, 22,  20, 22, 23   # left
].freeze

puts "=== Rotating 3D Cube Example ==="

# Initialize rendering (SDL3 window + WebGPU surface/device)
render = ExampleRendering.setup(
  title: "11 - Rotating Cube",
  width: WIDTH,
  height: HEIGHT
)
window = render.window
surface = render.surface
device = render.device
queue = render.queue
format = render.format

# Create vertex buffer
vertex_data = CUBE_VERTICES.pack("f*")
vertex_buffer = device.create_buffer(
  label: "cube vertex buffer",
  size: vertex_data.bytesize,
  usage: [:vertex, :copy_dst]
)
queue.write_buffer(vertex_buffer, 0, vertex_data)

# Create index buffer
index_data = CUBE_INDICES.pack("S*")
index_buffer = device.create_buffer(
  label: "cube index buffer",
  size: index_data.bytesize,
  usage: [:index, :copy_dst]
)
queue.write_buffer(index_buffer, 0, index_data)

# Create uniform buffer for MVP matrix (16 floats = 64 bytes)
uniform_buffer = device.create_buffer(
  label: "uniform buffer",
  size: 64,
  usage: [:uniform, :copy_dst]
)

# Create depth texture
depth_texture = device.create_texture(
  label: "depth texture",
  size: { width: WIDTH, height: HEIGHT, depth_or_array_layers: 1 },
  format: :depth24_plus,
  usage: :render_attachment
)
depth_view = depth_texture.create_view

# Create bind group layout
bind_group_layout = device.create_bind_group_layout(
  label: "uniform bind group layout",
  entries: [{
    binding: 0,
    visibility: :vertex,
    buffer: { type: :uniform }
  }]
)

# Create bind group
bind_group = device.create_bind_group(
  label: "uniform bind group",
  layout: bind_group_layout,
  entries: [{
    binding: 0,
    buffer: uniform_buffer,
    offset: 0,
    size: 64
  }]
)

# Create shader module
shader = device.create_shader_module(label: "cube shader", code: SHADER_CODE)

# Create render pipeline
pipeline_layout = device.create_pipeline_layout(bind_group_layouts: [bind_group_layout])
render_pipeline = device.create_render_pipeline(
  label: "cube pipeline",
  layout: pipeline_layout,
  vertex: {
    module: shader,
    entry_point: "vs_main",
    buffers: [{
      array_stride: 6 * 4,  # 6 floats * 4 bytes
      step_mode: :vertex,
      attributes: [
        { format: :float32x3, offset: 0,     shader_location: 0 },  # position
        { format: :float32x3, offset: 3 * 4, shader_location: 1 }   # color
      ]
    }]
  },
  fragment: {
    module: shader,
    entry_point: "fs_main",
    targets: [{ format: format }]
  },
  primitive: {
    topology: :triangle_list,
    cull_mode: :back,
    front_face: :ccw
  },
  depth_stencil: {
    format: :depth24_plus,
    depth_write_enabled: true,
    depth_compare: :less
  }
)

puts "Rendering rotating cube... (Press Escape or close window to exit)"

# Main render loop
running = true
frame_count = 0
start_time = Time.now

while running
  # Poll events
  events = window.poll_events

  # Check for quit or escape
  if window.should_close?(events) || window.key_pressed?(events, :escape)
    running = false
  end

  next unless running

  begin
    # Calculate MVP matrix
    elapsed = Time.now - start_time
    angle_y = elapsed * 0.5
    angle_x = elapsed * 0.3

    aspect = WIDTH.to_f / HEIGHT
    projection = MatrixMath.perspective(Math::PI / 4.0, aspect, 0.1, 100.0)
    view = MatrixMath.translate(0.0, 0.0, -6.0)
    model = MatrixMath.multiply(MatrixMath.rotate_y(angle_y), MatrixMath.rotate_x(angle_x))

    mvp = MatrixMath.multiply(MatrixMath.multiply(projection, view), model)

    # Update uniform buffer
    queue.write_buffer(uniform_buffer, 0, mvp.pack("f*"))

    # Get current texture from surface
    texture = surface.current_texture
    color_view = texture.create_view

    # Create command encoder
    encoder = device.create_command_encoder(label: "render encoder")

    # Begin render pass
    pass = encoder.begin_render_pass(
      label: "main pass",
      color_attachments: [{
        view: color_view,
        load_op: :clear,
        store_op: :store,
        clear_value: { r: 0.1, g: 0.1, b: 0.15, a: 1.0 }
      }],
      depth_stencil_attachment: {
        view: depth_view,
        depth_load_op: :clear,
        depth_store_op: :store,
        depth_clear_value: 1.0
      }
    )

    # Draw cube
    pass.set_pipeline(render_pipeline)
    pass.set_bind_group(0, bind_group)
    pass.set_vertex_buffer(0, vertex_buffer)
    pass.set_index_buffer(index_buffer, :uint16)
    pass.draw_indexed(CUBE_INDICES.size)
    pass.end_pass

    # Submit and present
    command_buffer = encoder.finish
    queue.submit([command_buffer])
    surface.present

    # Cleanup per-frame resources
    color_view.release
    command_buffer.release
    encoder.release
    pass.release

    frame_count += 1
  rescue WGPU::SurfaceError => e
    puts "Surface error: #{e.message}, skipping frame"
  end
end

elapsed_time = Time.now - start_time
fps = frame_count / elapsed_time
puts "Rendered #{frame_count} frames in #{elapsed_time.round(2)}s (#{fps.round(1)} FPS)"

# Cleanup
bind_group.release
bind_group_layout.release
uniform_buffer.release
depth_view.release
depth_texture.release
vertex_buffer.release
index_buffer.release
render_pipeline.release
pipeline_layout.release
shader.release
ExampleRendering.cleanup(render)

puts "Done!"
