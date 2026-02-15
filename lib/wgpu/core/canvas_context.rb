# frozen_string_literal: true

module WGPU
  class CanvasContext
    attr_reader :physical_size

    def initialize(instance, present_info = {})
      @instance = instance
      @present_info = present_info || {}
      @surface = @present_info[:surface]
      @physical_size = [0, 0]
      @config = nil
    end

    def set_physical_size(width, height)
      raise ArgumentError, "width and height must be non-negative" if width.to_i.negative? || height.to_i.negative?

      @physical_size = [width.to_i, height.to_i]
    end

    def get_preferred_format(adapter)
      ensure_surface
      @surface.get_preferred_format(adapter)
    end

    def get_configuration
      @config
    end

    def configure(device:, format: nil, usage: :render_attachment, view_formats: [], color_space: "srgb", tone_mapping: nil, alpha_mode: :opaque, width: nil, height: nil, present_mode: :fifo)
      ensure_surface
      color_space # reserved for API parity
      tone_mapping # reserved for API parity

      width = width || @physical_size[0]
      height = height || @physical_size[1]
      raise SurfaceError, "Surface size must be positive before configure" if width.to_i <= 0 || height.to_i <= 0

      resolved_format = format || get_preferred_format(device.adapter)
      @surface.configure(
        device: device,
        format: resolved_format,
        usage: usage,
        width: width,
        height: height,
        present_mode: present_mode,
        alpha_mode: alpha_mode,
        view_formats: view_formats
      )
      @config = {
        device: device,
        format: resolved_format,
        usage: usage,
        view_formats: view_formats,
        color_space: color_space,
        tone_mapping: tone_mapping,
        alpha_mode: alpha_mode,
        width: width,
        height: height,
        present_mode: present_mode
      }
    end

    def unconfigure
      @surface&.unconfigure
      @config = nil
    end

    def get_current_texture
      raise SurfaceError, "Canvas context must be configured before get_current_texture" unless @config

      @surface.current_texture
    end

    def present
      @surface&.present
    end

    def release
      @surface&.release
      @surface = nil
      @config = nil
    end

    private

    def ensure_surface
      return if @surface

      @surface = case @present_info[:platform]&.to_sym
                 when :macos
                   Surface.from_metal_layer(@instance, @present_info.fetch(:layer))
                 when :windows
                   Surface.from_windows_hwnd(@instance, @present_info[:hinstance], @present_info.fetch(:hwnd))
                 when :x11, :linux_x11
                   Surface.from_xlib_window(@instance, @present_info.fetch(:display), @present_info.fetch(:window))
                 when :wayland, :linux_wayland
                   Surface.from_wayland_surface(@instance, @present_info.fetch(:display), @present_info.fetch(:surface))
                 else
                   raise SurfaceError, "Cannot build surface from present_info: #{@present_info.inspect}"
                 end
    end
  end
end
