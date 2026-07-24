# frozen_string_literal: true

module WGPU
  class Surface
    attr_reader :handle

    # Creates a surface backed by a Core Animation Metal layer.
    # @return [Surface]
    # @raise [SurfaceError] if native surface creation fails
    def self.from_metal_layer(instance, layer)
      source = Native::SurfaceSourceMetalLayer.new
      source[:chain][:next] = nil
      source[:chain][:s_type] = Native::SType[:surface_source_metal_layer]
      source[:layer] = layer

      desc = Native::SurfaceDescriptor.new
      desc[:next_in_chain] = source.to_ptr
      desc[:label][:data] = nil
      desc[:label][:length] = 0

      handle = Native.wgpuInstanceCreateSurface(instance.handle, desc)
      raise SurfaceError, "Failed to create surface from Metal layer" if handle.null?

      new(handle, instance)
    end

    # Creates a surface backed by a Windows window handle.
    # @return [Surface]
    # @raise [SurfaceError] if native surface creation fails
    def self.from_windows_hwnd(instance, hinstance, hwnd)
      source = Native::SurfaceSourceWindowsHWND.new
      source[:chain][:next] = nil
      source[:chain][:s_type] = Native::SType[:surface_source_windows_hwnd]
      source[:hinstance] = hinstance
      source[:hwnd] = hwnd

      desc = Native::SurfaceDescriptor.new
      desc[:next_in_chain] = source.to_ptr
      desc[:label][:data] = nil
      desc[:label][:length] = 0

      handle = Native.wgpuInstanceCreateSurface(instance.handle, desc)
      raise SurfaceError, "Failed to create surface from Windows HWND" if handle.null?

      new(handle, instance)
    end

    # Creates a surface backed by an Xlib window.
    # @return [Surface]
    # @raise [SurfaceError] if native surface creation fails
    def self.from_xlib_window(instance, display, window)
      source = Native::SurfaceSourceXlibWindow.new
      source[:chain][:next] = nil
      source[:chain][:s_type] = Native::SType[:surface_source_xlib_window]
      source[:display] = display
      source[:window] = window

      desc = Native::SurfaceDescriptor.new
      desc[:next_in_chain] = source.to_ptr
      desc[:label][:data] = nil
      desc[:label][:length] = 0

      handle = Native.wgpuInstanceCreateSurface(instance.handle, desc)
      raise SurfaceError, "Failed to create surface from Xlib window" if handle.null?

      new(handle, instance)
    end

    # Creates a surface backed by a Wayland surface.
    # @return [Surface]
    # @raise [SurfaceError] if native surface creation fails
    def self.from_wayland_surface(instance, display, surface)
      source = Native::SurfaceSourceWaylandSurface.new
      source[:chain][:next] = nil
      source[:chain][:s_type] = Native::SType[:surface_source_wayland_surface]
      source[:display] = display
      source[:surface] = surface

      desc = Native::SurfaceDescriptor.new
      desc[:next_in_chain] = source.to_ptr
      desc[:label][:data] = nil
      desc[:label][:length] = 0

      handle = Native.wgpuInstanceCreateSurface(instance.handle, desc)
      raise SurfaceError, "Failed to create surface from Wayland surface" if handle.null?

      new(handle, instance)
    end

    # Wraps a native presentation surface.
    # @param handle [FFI::Pointer] native surface handle
    # @param instance [Instance] owning instance
    def initialize(handle, instance)
      @handle = handle
      @instance = instance
      @configured = false
      @config = nil
    end

    # Configures this surface for presentation by a device.
    # @return [Hash] stored configuration
    def configure(device:, format:, usage: :render_attachment, width:, height:, present_mode: :fifo, alpha_mode: :auto, view_formats: [])
      config = Native::SurfaceConfiguration.new
      config[:next_in_chain] = nil
      config[:device] = device.handle
      config[:format] = Native::EnumHelper.coerce(Native::TextureFormat, format, name: "surface format")
      config[:usage] = normalize_usage(usage)
      config[:width] = width
      config[:height] = height
      config[:view_format_count] = view_formats.size
      if view_formats.empty?
        @view_formats_ptr = nil
        config[:view_formats] = nil
      else
        format_values = view_formats.map do |view_format|
          Native::EnumHelper.coerce(Native::TextureFormat, view_format, name: "view format")
        end
        @view_formats_ptr = FFI::MemoryPointer.new(:uint32, format_values.size)
        @view_formats_ptr.write_array_of_uint32(format_values)
        config[:view_formats] = @view_formats_ptr
      end
      config[:alpha_mode] = Native::EnumHelper.coerce(
        Native::CompositeAlphaMode,
        alpha_mode,
        name: "alpha mode"
      )
      config[:present_mode] = Native::EnumHelper.coerce(
        Native::PresentMode,
        present_mode,
        name: "present mode"
      )

      Native.wgpuSurfaceConfigure(@handle, config)
      release_device_callback_lifetime
      @configured = true
      @device = device
      attach_device_callback_lifetime(device)
      @config = {
        device: device,
        format: format,
        usage: usage,
        width: width,
        height: height,
        present_mode: present_mode,
        alpha_mode: alpha_mode,
        view_formats: view_formats
      }
    end

    # Removes the current surface configuration.
    # @return [void]
    def unconfigure
      Native.wgpuSurfaceUnconfigure(@handle)
      release_device_callback_lifetime
      @configured = false
      @device = nil
      @config = nil
    end

    # Acquires the current surface texture.
    # @return [Texture]
    # @raise [SurfaceError] if unconfigured or no texture is returned
    # @raise [SurfaceAcquisitionError] if the surface status is unsuccessful
    def current_texture
      raise SurfaceError, "Surface is not configured" unless @configured

      surface_texture = Native::SurfaceTexture.new
      Native.wgpuSurfaceGetCurrentTexture(@handle, surface_texture)

      status = Native::SurfaceGetCurrentTextureStatus[surface_texture[:status]]
      unless status == :success_optimal || status == :success_suboptimal
        raise SurfaceAcquisitionError.new(status)
      end

      texture_ptr = surface_texture[:texture]
      if texture_ptr.nil? || texture_ptr.null?
        raise SurfaceError, "Surface returned null texture"
      end

      Texture.from_handle(texture_ptr, surface_status: status, device: @device)
    end

    # Acquires the texture for the current presentation frame.
    #
    # @return [Texture] acquired surface texture
    # @raise [SurfaceError] if the surface is not configured
    # @raise [SurfaceAcquisitionError] if acquisition fails
    def get_current_texture
      current_texture
    end

    # Presents the current surface texture.
    # @return [void]
    def present
      Native.wgpuSurfacePresent(@handle)
    end

    # Returns the most recent surface configuration.
    #
    # @return [Hash, nil] configuration options, or +nil+ when unconfigured
    def get_configuration
      @config
    end

    # Returns the first surface format supported by an adapter.
    #
    # @param adapter [Adapter] adapter used to query surface capabilities
    # @return [Symbol] preferred texture format
    def get_preferred_format(adapter)
      caps = capabilities(adapter)
      caps[:formats].first || :bgra8_unorm
    end

    # Returns the formats, presentation modes, alpha modes, and usages supported by an adapter.
    # @param adapter [Adapter] adapter to query
    # @return [Hash]
    def capabilities(adapter)
      caps = Native::SurfaceCapabilities.new
      Native.wgpuSurfaceGetCapabilities(@handle, adapter.handle, caps)

      formats = []
      if caps[:format_count] > 0 && !caps[:formats].null?
        formats = caps[:formats].read_array_of_uint32(caps[:format_count]).map do |f|
          Native::TextureFormat[f]
        end
      end

      present_modes = []
      if caps[:present_mode_count] > 0 && !caps[:present_modes].null?
        present_modes = caps[:present_modes].read_array_of_uint32(caps[:present_mode_count]).map do |m|
          Native::PresentMode[m]
        end
      end

      alpha_modes = []
      if caps[:alpha_mode_count] > 0 && !caps[:alpha_modes].null?
        alpha_modes = caps[:alpha_modes].read_array_of_uint32(caps[:alpha_mode_count]).map do |a|
          Native::CompositeAlphaMode[a]
        end
      end

      {
        formats: formats,
        present_modes: present_modes,
        alpha_modes: alpha_modes,
        usages: caps[:usages]
      }
    ensure
      Native.wgpuSurfaceCapabilitiesFreeMembers(caps) if caps
    end

    # Releases the native surface handle.
    #
    # Calling this method more than once has no effect.
    # @return [void]
    def release
      return if @handle.null?
      Native.wgpuSurfaceRelease(@handle)
      @handle = FFI::Pointer::NULL
    end

    private

    def normalize_usage(usage)
      Native::EnumHelper.coerce_flags(Native::TextureUsage, usage, name: "surface usage")
    end
  end
end
