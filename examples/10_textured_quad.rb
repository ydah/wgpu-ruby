#!/usr/bin/env ruby
# frozen_string_literal: true

# Example 10: Textured Quad
# Demonstrates texture creation, sampling, and bind groups.
# Creates a procedural checkerboard texture and displays it on a quad.
#
# Requirements:
#   - SDL3 library installed (brew install sdl3 on macOS)
#   - sdl3 gem

require_relative "rendering_example_helper"

SHADER_CODE = File.read(File.expand_path("shaders/textured_quad.wgsl", __dir__))

WIDTH = 800
HEIGHT = 600
TEXTURE_SIZE = 64

# Generate a checkerboard pattern
def create_checkerboard_texture(size, tile_size = 8)
  data = []
  size.times do |y|
    size.times do |x|
      tile_x = x / tile_size
      tile_y = y / tile_size
      is_white = (tile_x + tile_y).even?

      if is_white
        data.push(255, 255, 255, 255)  # White (RGBA)
      else
        data.push(64, 64, 64, 255)     # Dark gray (RGBA)
      end
    end
  end
  data.pack("C*")
end

puts "=== Textured Quad Example ==="

# Initialize rendering (SDL3 window + WebGPU surface/device)
render = ExampleRendering.setup(
  title: "10 - Textured Quad",
  width: WIDTH,
  height: HEIGHT
)
window = render.window
surface = render.surface
device = render.device
queue = render.queue
format = render.format

# Create texture
texture = device.create_texture(
  label: "checkerboard texture",
  size: { width: TEXTURE_SIZE, height: TEXTURE_SIZE, depth_or_array_layers: 1 },
  format: :rgba8_unorm,
  usage: [:texture_binding, :copy_dst]
)

# Upload texture data
texture_data = create_checkerboard_texture(TEXTURE_SIZE)
queue.write_texture(
  destination: { texture: texture, mip_level: 0, origin: { x: 0, y: 0, z: 0 } },
  data: texture_data,
  data_layout: { offset: 0, bytes_per_row: TEXTURE_SIZE * 4, rows_per_image: TEXTURE_SIZE },
  size: { width: TEXTURE_SIZE, height: TEXTURE_SIZE, depth_or_array_layers: 1 }
)

texture_view = texture.create_view

# Create sampler
sampler = device.create_sampler(
  label: "texture sampler",
  mag_filter: :linear,
  min_filter: :linear,
  address_mode_u: :repeat,
  address_mode_v: :repeat
)

# Create bind group layout
bind_group_layout = device.create_bind_group_layout(
  label: "texture bind group layout",
  entries: [
    {
      binding: 0,
      visibility: :fragment,
      texture: { sample_type: :float, view_dimension: :d2 }
    },
    {
      binding: 1,
      visibility: :fragment,
      sampler: { type: :filtering }
    }
  ]
)

# Create bind group
bind_group = device.create_bind_group(
  label: "texture bind group",
  layout: bind_group_layout,
  entries: [
    { binding: 0, texture_view: texture_view },
    { binding: 1, sampler: sampler }
  ]
)

# Create shader module
shader = device.create_shader_module(label: "textured quad shader", code: SHADER_CODE)

# Create render pipeline
pipeline_layout = device.create_pipeline_layout(bind_group_layouts: [bind_group_layout])
render_pipeline = device.create_render_pipeline(
  label: "textured quad pipeline",
  layout: pipeline_layout,
  vertex: {
    module: shader,
    entry_point: "vs_main"
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

puts "Rendering textured quad... (Press Escape or close window to exit)"

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

  begin
    # Get current texture from surface
    surface_texture = surface.current_texture
    view = surface_texture.create_view

    # Create command encoder
    encoder = device.create_command_encoder(label: "render encoder")

    # Begin render pass
    pass = encoder.begin_render_pass(
      label: "main pass",
      color_attachments: [{
        view: view,
        load_op: :clear,
        store_op: :store,
        clear_value: { r: 0.2, g: 0.2, b: 0.3, a: 1.0 }
      }]
    )

    # Draw textured quad
    pass.set_pipeline(render_pipeline)
    pass.set_bind_group(0, bind_group)
    pass.draw(6)  # 6 vertices = 2 triangles
    pass.end_pass

    # Submit and present
    command_buffer = encoder.finish
    queue.submit([command_buffer])
    surface.present

    # Cleanup per-frame resources
    view.release
    command_buffer.release
    encoder.release
    pass.release

    frame_count += 1
  rescue WGPU::SurfaceError => e
    puts "Surface error: #{e.message}, skipping frame"
  end
end

puts "Rendered #{frame_count} frames"

# Cleanup
bind_group.release
bind_group_layout.release
sampler.release
texture_view.release
texture.release
render_pipeline.release
pipeline_layout.release
shader.release
ExampleRendering.cleanup(render)

puts "Done!"
