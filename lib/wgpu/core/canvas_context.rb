# frozen_string_literal: true

module WGPU
  class CanvasContext
    attr_reader :physical_size

    # Creates a canvas context for platform presentation information.
    # @param instance [Instance] owning WebGPU instance
    # @param present_info [Hash] platform handles or an existing surface
    def initialize(instance, present_info = {})
      @instance = instance
      @present_info = present_info || {}
      @surface = @present_info[:surface]
      @physical_size = [0, 0]
      @config = nil
    end

    # Updates the drawable's physical pixel size.
    # @param width [Integer] width in pixels
    # @param height [Integer] height in pixels
    # @return [Array<Integer>] stored width and height
    # @raise [ArgumentError] if either dimension is negative
    def set_physical_size(width, height)
      raise ArgumentError, "width and height must be non-negative" if width.to_i.negative? || height.to_i.negative?

      @physical_size = [width.to_i, height.to_i]
    end

    # Returns the surface format preferred by an adapter.
    #
    # @param adapter [Adapter] adapter used to query surface capabilities
    # @return [Symbol] preferred texture format
    def get_preferred_format(adapter)
      ensure_surface
      @surface.get_preferred_format(adapter)
    end

    # Returns the most recent canvas configuration.
    #
    # @return [Hash, nil] configuration options, or +nil+ when unconfigured
    def get_configuration
      @config
    end

    # Configures the backing surface for presentation.
    # @param device [Device] device used to render frames
    # @param format [Symbol, nil] surface texture format
    # @return [Hash] resolved canvas configuration
    # @raise [SurfaceError] if no surface exists or dimensions are not positive
    def configure(device:, format: nil, usage: :render_attachment, view_formats: [], color_space: "srgb", tone_mapping: nil, alpha_mode: :opaque, width: nil, height: nil, present_mode: :fifo)
      ensure_surface

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

    # Removes the current surface configuration.
    # @return [void]
    def unconfigure
      @surface&.unconfigure
      @config = nil
    end

    # Acquires the texture for the current presentation frame.
    #
    # @return [Texture] acquired surface texture
    # @raise [SurfaceError] if the context has not been configured
    # @raise [SurfaceAcquisitionError] if acquisition fails
    def get_current_texture
      raise SurfaceError, "Canvas context must be configured before get_current_texture" unless @config

      @surface.current_texture
    end

    # Presents the current surface texture.
    # @return [void]
    def present
      @surface&.present
    end

    # Releases the backing surface and clears the configuration.
    #
    # @return [void]
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
