# Getting started: rendering

Rendering adds a window-system integration. The bundled helper uses SDL3, but
surfaces themselves are independent of SDL and may be created from native
Metal, Win32, Xlib, or Wayland handles.

Add the optional dependency:

```ruby
gem "wgpu"
gem "sdl3", "~> 1.0"
```

Install the SDL3 system library, then load the helper explicitly:

```ruby
require "wgpu"
require "wgpu/window"

window = WGPU::Window::SDLWindow.new(
  title: "WebGPU",
  width: 800,
  height: 600
)
instance = WGPU::Instance.new
surface = window.create_surface(instance)
adapter = instance.request_adapter(compatible_surface: surface)
device = adapter.request_device

format = surface.capabilities(adapter).fetch(:formats).first
width, height = window.drawable_size
surface.configure(
  device: device,
  format: format,
  width: width,
  height: height,
  present_mode: :fifo
)
```

For every frame, acquire `surface.current_texture`, create a view, encode and
submit a render pass, call `surface.present`, and release frame-local objects.
The returned texture exposes `surface_status` as `:success_optimal` or
`:success_suboptimal`. Acquisition failures raise
`WGPU::SurfaceAcquisitionError`; inspect its `status` reader for `:timeout`,
`:outdated`, `:lost`, `:out_of_memory`, or `:device_lost`. Reconfigure on
`:outdated`/`:lost` after re-reading the drawable size.
When `drawable_size` changes, configure the surface again with positive pixel
dimensions. Do not render while a minimized window reports zero dimensions.

`Surface` is the low-level native-window API. `CanvasContext` owns and
delegates to a surface while retaining the familiar configure/acquire/present
shape. Integrations other than SDL3 can pass an `FFI::Pointer` obtained from
their window toolkit to `Surface.from_metal_layer`,
`Surface.from_windows_hwnd`, `Surface.from_xlib_window`, or
`Surface.from_wayland_surface`. The application must keep the corresponding
native window/display/layer alive longer than the surface; wgpu-ruby does not
take ownership of those platform objects.

[`examples/09_clear_color.rb`](../examples/09_clear_color.rb) is the smallest
resizable render loop. The other rendering examples cover vertex/index
buffers, textures, bind groups, depth testing, and uniform updates.
