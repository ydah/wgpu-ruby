#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../lib/wgpu"

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
    require_relative "../lib/wgpu/window"

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

  def self.resize_if_needed(setup, force: false, drawable_size: nil)
    width, height = drawable_size || setup.window.drawable_size
    return false if width <= 0 || height <= 0
    return false if !force && width == setup.width && height == setup.height

    setup.surface.configure(
      device: setup.device,
      format: setup.format,
      width: width,
      height: height,
      present_mode: setup.present_mode
    )
    setup.width = width
    setup.height = height
    yield(width, height) if block_given?
    true
  end

  def self.acquire_surface_texture(setup, &on_resize)
    drawable_size = setup.window.drawable_size
    return nil if drawable_size.any? { |dimension| dimension <= 0 }

    resize_if_needed(setup, drawable_size: drawable_size, &on_resize)
    recovery_attempted = false

    begin
      setup.surface.current_texture
    rescue WGPU::SurfaceAcquisitionError => e
      case e.status
      when :timeout
        nil
      when :outdated, :lost
        raise if recovery_attempted

        drawable_size = setup.window.drawable_size
        raise unless resize_if_needed(setup, force: true, drawable_size: drawable_size, &on_resize)

        recovery_attempted = true
        retry
      else
        raise
      end
    end
  end

  def self.cleanup(setup)
    setup.surface.release
    setup.device.release
    setup.adapter.release
    setup.instance.release
    setup.window.close
  end
end
