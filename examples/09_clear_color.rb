#!/usr/bin/env ruby
# frozen_string_literal: true

# Example 09: Animated Clear Color
# Demonstrates the render loop with animated background color.
# APIs: resizable surface configuration, texture/view, render pass, present.
# Expected: the animated background follows the drawable size after resizing.
# No geometry is drawn - just clearing the screen with changing colors.
#
# Requirements:
#   - SDL3 library installed (brew install sdl3 on macOS)
#   - sdl3 gem

require_relative "rendering_example_helper"

WIDTH = 800
HEIGHT = 600

puts "=== Animated Clear Color Example ==="

# Initialize rendering (SDL3 window + WebGPU surface/device)
render = ExampleRendering.setup(
  title: "09 - Clear Color Animation",
  width: WIDTH,
  height: HEIGHT
)
window = render.window
surface = render.surface
device = render.device
queue = render.queue

puts "Animating background color... (Press Escape or close window to exit)"

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

  texture = nil
  view = nil
  encoder = nil
  pass = nil
  command_buffer = nil

  begin
    # Calculate animated color based on time
    elapsed = Time.now - start_time
    r = (Math.sin(elapsed * 0.5) + 1.0) / 2.0
    g = (Math.sin((elapsed * 0.7) + 2.0) + 1.0) / 2.0
    b = (Math.sin((elapsed * 0.9) + 4.0) + 1.0) / 2.0

    # Get current texture from surface
    texture = ExampleRendering.acquire_surface_texture(render)
    next unless texture

    view = texture.create_view

    # Create command encoder
    encoder = device.create_command_encoder(label: "render encoder")

    # Begin render pass with animated clear color
    pass = encoder.begin_render_pass(
      label: "main pass",
      color_attachments: [{
        view: view,
        load_op: :clear,
        store_op: :store,
        clear_value: { r: r, g: g, b: b, a: 1.0 }
      }]
    )

    # No drawing - just end the pass
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

elapsed_time = Time.now - start_time
fps = frame_count / elapsed_time
puts "Rendered #{frame_count} frames in #{elapsed_time.round(2)}s (#{fps.round(1)} FPS)"

# Cleanup
ExampleRendering.cleanup(render)

puts "Done!"
