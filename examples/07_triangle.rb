#!/usr/bin/env ruby
# frozen_string_literal: true

# Example 07: Basic Triangle Rendering
# Demonstrates the most basic WebGPU rendering: drawing a colored triangle to a window.
#
# Requirements:
#   - SDL3 library installed (brew install sdl3 on macOS)
#   - sdl3 gem

require_relative "rendering_example_helper"

SHADER_CODE = File.read(File.expand_path("shaders/triangle.wgsl", __dir__))

WIDTH = 800
HEIGHT = 600

puts "=== Triangle Rendering Example ==="

# Initialize rendering (SDL3 window + WebGPU surface/device)
render = ExampleRendering.setup(
  title: "07 - Triangle",
  width: WIDTH,
  height: HEIGHT
)
window = render.window
surface = render.surface
device = render.device
queue = render.queue
format = render.format
puts "Using surface format: #{format}"

# Create shader module
shader = device.create_shader_module(label: "triangle shader", code: SHADER_CODE)

# Create render pipeline
pipeline_layout = device.create_pipeline_layout(bind_group_layouts: [])
render_pipeline = device.create_render_pipeline(
  label: "triangle pipeline",
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

puts "Rendering triangle... (Press Escape or close window to exit)"

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
    texture = surface.current_texture
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

    # Draw triangle
    pass.set_pipeline(render_pipeline)
    pass.draw(3)
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
render_pipeline.release
pipeline_layout.release
shader.release
ExampleRendering.cleanup(render)

puts "Done!"
