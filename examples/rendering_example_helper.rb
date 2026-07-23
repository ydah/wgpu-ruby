#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../lib/wgpu"
require_relative "../lib/wgpu/window"

module ExampleRendering
  Setup = Struct.new(
    :window,
    :instance,
    :surface,
    :adapter,
    :device,
    :queue,
    :format,
    :width,
    :height,
    :present_mode,
    keyword_init: true
  )

  def self.setup(title:, width:, height:, present_mode: :fifo)
    window = WGPU::Window::SDLWindow.new(title: title, width: width, height: height)

    instance = WGPU::Instance.new
    surface = window.create_surface(instance)

    adapter = instance.request_adapter(compatible_surface: surface)
    device = adapter.request_device
    queue = device.queue

    format = surface.capabilities(adapter).fetch(:formats).first
    surface.configure(
      device: device,
      format: format,
      width: width,
      height: height,
      present_mode: present_mode
    )

    Setup.new(
      window: window,
      instance: instance,
      surface: surface,
      adapter: adapter,
      device: device,
      queue: queue,
      format: format,
      width: width,
      height: height,
      present_mode: present_mode
    )
  end

  def self.resize_if_needed(setup)
    width, height = setup.window.drawable_size
    return false if width <= 0 || height <= 0
    return false if width == setup.width && height == setup.height

    setup.surface.configure(
      device: setup.device,
      format: setup.format,
      width: width,
      height: height,
      present_mode: setup.present_mode
    )
    setup.width = width
    setup.height = height
    true
  end

  def self.cleanup(setup)
    setup.surface.release
    setup.device.release
    setup.adapter.release
    setup.instance.release
    setup.window.close
  end
end
