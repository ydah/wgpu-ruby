# Troubleshooting

## Native library is not found

Run `bundle exec rake wgpu:install`. The error lists every searched cache path.
For a custom build, set `WGPU_LIB_PATH` to the shared library file, not its
directory. See [installation](installation.md).

## Download or checksum fails

The installer deletes an archive whose SHA-256 differs from the pinned release
metadata. Retry on a trusted network. Do not bypass the checksum; download the
matching artifact manually and set `WGPU_LIB_PATH` if GitHub Releases is
unavailable.

## No adapter is available

Update the platform GPU driver. On headless Linux, install Vulkan loader and
Mesa lavapipe, set `VK_ICD_FILENAMES` to the lavapipe ICD JSON, and inspect
`vulkaninfo --summary`. `WGPU_BACKEND=vulkan` can make backend selection
explicit.

## A synchronous operation hangs

Pass `timeout:` to adapter/device requests, `Buffer#map_sync`,
`Device#pop_error_scope`, or `Queue#on_submitted_work_done`. A timeout raises
`WGPU::TimeoutError`. In an event loop, regularly call
`Instance#process_events` or `Device#poll`.

## Texture readback rejects bytes_per_row

Buffer/texture copy rows must be 256-byte aligned. Calculate the value with
`WGPU::TextureFormat.aligned_bytes_per_row(width, format)` and account for
padding when decoding each row.

## SDL3 cannot be loaded

Compute code should only `require "wgpu"`. Rendering code must separately add
the `sdl3` Ruby gem, install the SDL3 system library, and then require
`wgpu/window`.

## Diagnosing validation and shader errors

Use `device.on_uncaptured_error`, scoped errors, and labels. Compilation-info
validation is guarded on pinned wgpu-native v27 because its exported function
is a panic stub; see [Shaders and diagnostics](shaders.md). Set
`WGPU_DEBUG_LEAKS=1` in development to warn about wrappers that reach GC or
process exit without `release`.
