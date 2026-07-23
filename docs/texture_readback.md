# Texture readback

`WGPU::TextureFormat` exposes WebGPU texel-block calculations:

```ruby
tight = WGPU::TextureFormat.bytes_per_row(width, :rgba8_unorm)
stride = WGPU::TextureFormat.aligned_bytes_per_row(width, :rgba8_unorm)
```

`block_size` returns the bytes in one texel block, while `block_dimensions`
returns its width and height. Compressed BC, ETC2/EAC, and ASTC formats use
their real block dimensions. Formats whose depth representation is
implementation-defined do not claim a portable copy footprint. Combined
depth/stencil copies require an explicit `aspect:`.

`Queue#read_texture` validates that `bytes_per_row` is a multiple of WebGPU's
256-byte copy alignment and large enough for the requested width and format.
Use `aligned_bytes_per_row` when the tight row is not already aligned. Automatic
padding and mipmap generation are intentionally outside this low-level binding.
