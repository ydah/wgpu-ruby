# frozen_string_literal: true

begin
  require "sdl3"
rescue LoadError => e
  raise LoadError,
    "wgpu/window requires the optional `sdl3` gem. " \
    "Add `gem \"sdl3\", \"~> 1.0\"` and install the SDL3 system library. " \
    "(original error: #{e.message})"
end

module WGPU
  module Window
    class SDLWindow
      attr_reader :width, :height, :window

      # Property names for native window handles
      SDL_PROP_WINDOW_WIN32_HWND_POINTER = "SDL.window.win32.hwnd"
      SDL_PROP_WINDOW_WIN32_INSTANCE_POINTER = "SDL.window.win32.instance"
      SDL_PROP_WINDOW_X11_DISPLAY_POINTER = "SDL.window.x11.display"
      SDL_PROP_WINDOW_X11_WINDOW_NUMBER = "SDL.window.x11.window"
      SDL_PROP_WINDOW_WAYLAND_DISPLAY_POINTER = "SDL.window.wayland.display"
      SDL_PROP_WINDOW_WAYLAND_SURFACE_POINTER = "SDL.window.wayland.surface"

      def initialize(title:, width: 800, height: 600, resizable: true)
        @width = width
        @height = height
        @metal_view = nil

        flags = 0
        flags |= SDL3::Raw::SDL_WINDOW_RESIZABLE if resizable
        flags |= SDL3::Raw::SDL_WINDOW_HIGH_PIXEL_DENSITY if macos?
        flags |= SDL3::Raw::SDL_WINDOW_METAL if macos?

        @window = SDL3::Window.new(title, width, height, flags)
      end

      # Creates a presentation surface for this native window.
      #
      # @param instance [Instance] WebGPU instance that owns the surface
      # @return [Surface] platform-specific presentation surface
      # @raise [WindowError] if the platform or native window handle is unsupported
      def create_surface(instance)
        case platform
        when :macos
          create_metal_surface(instance)
        when :windows
          create_windows_surface(instance)
        when :linux_x11
          create_x11_surface(instance)
        when :linux_wayland
          create_wayland_surface(instance)
        else
          raise WindowError, "Unsupported platform: #{RbConfig::CONFIG["host_os"]}"
        end
      end

      # Collects currently pending SDL events.
      #
      # @return [Array] events in delivery order
      def poll_events
        events = []
        SDL3::Event.each do |event|
          events << event
        end
        events
      end

      def should_close?(events)
        events.any?(&:quit?)
      end

      def key_pressed?(events, key)
        scancode = case key
                   when :escape then SDL3::Raw::SDL_SCANCODE_ESCAPE
                   when :space then SDL3::Raw::SDL_SCANCODE_SPACE
                   when :return, :enter then SDL3::Raw::SDL_SCANCODE_RETURN
                   else key
                   end

        events.any? do |event|
          next unless event.key_down?

          event_scancode = event.raw[:key][:scancode] rescue nil
          event_scancode == scancode
        end
      end

      # Returns the drawable size in physical pixels.
      #
      # @return [Array(Integer, Integer)] width and height
      def drawable_size
        @window.size_in_pixels
      rescue
        [@width, @height]
      end

      # Destroys platform-specific resources and the SDL window.
      #
      # @return [void]
      def close
        if @metal_view && !@metal_view.null?
          SDL3::Raw.SDL_Metal_DestroyView(@metal_view)
          @metal_view = nil
        end
        @window.destroy if @window
      end

      private

      def window_pointer
        @window.to_ptr
      end

      def window_properties
        SDL3::Raw.SDL_GetWindowProperties(window_pointer)
      end

      def create_metal_surface(instance)
        ptr = window_pointer
        raise WindowError, "Could not get window pointer" if ptr.nil? || ptr.null?

        @metal_view = SDL3::Raw.SDL_Metal_CreateView(ptr)
        raise WindowError, "Failed to create Metal view" if @metal_view.nil? || @metal_view.null?

        layer = SDL3::Raw.SDL_Metal_GetLayer(@metal_view)
        raise WindowError, "Failed to get Metal layer" if layer.nil? || layer.null?

        Surface.from_metal_layer(instance, layer)
      end

      def create_windows_surface(instance)
        ptr = window_pointer
        raise WindowError, "Could not get window pointer" if ptr.nil? || ptr.null?

        props = window_properties
        raise WindowError, "Failed to get window properties" if props == 0

        hwnd = SDL3::Raw.SDL_GetPointerProperty(props, SDL_PROP_WINDOW_WIN32_HWND_POINTER, nil)
        hinstance = SDL3::Raw.SDL_GetPointerProperty(props, SDL_PROP_WINDOW_WIN32_INSTANCE_POINTER, nil)
        raise WindowError, "Failed to get Windows window info" unless hwnd

        Surface.from_windows_hwnd(instance, hinstance, hwnd)
      end

      def create_x11_surface(instance)
        ptr = window_pointer
        raise WindowError, "Could not get window pointer" if ptr.nil? || ptr.null?

        props = window_properties
        raise WindowError, "Failed to get window properties" if props == 0

        display = SDL3::Raw.SDL_GetPointerProperty(props, SDL_PROP_WINDOW_X11_DISPLAY_POINTER, nil)
        window_id = SDL3::Raw.SDL_GetNumberProperty(props, SDL_PROP_WINDOW_X11_WINDOW_NUMBER, 0)
        raise WindowError, "Failed to get X11 window info" unless display

        Surface.from_xlib_window(instance, display, window_id)
      end

      def create_wayland_surface(instance)
        ptr = window_pointer
        raise WindowError, "Could not get window pointer" if ptr.nil? || ptr.null?

        props = window_properties
        raise WindowError, "Failed to get window properties" if props == 0

        display = SDL3::Raw.SDL_GetPointerProperty(props, SDL_PROP_WINDOW_WAYLAND_DISPLAY_POINTER, nil)
        wl_surface = SDL3::Raw.SDL_GetPointerProperty(props, SDL_PROP_WINDOW_WAYLAND_SURFACE_POINTER, nil)
        raise WindowError, "Failed to get Wayland window info" unless display

        Surface.from_wayland_surface(instance, display, wl_surface)
      end

      def platform
        case RbConfig::CONFIG["host_os"]
        when /darwin/
          :macos
        when /mswin|mingw/
          :windows
        when /linux/
          if ENV["XDG_SESSION_TYPE"] == "wayland" || ENV["WAYLAND_DISPLAY"]
            :linux_wayland
          else
            :linux_x11
          end
        else
          :unknown
        end
      end

      def macos?
        platform == :macos
      end
    end

    class WindowError < StandardError; end
  end
end
