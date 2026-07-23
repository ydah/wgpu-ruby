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

For example, an `rgba8_unorm` row that is 65 pixels wide contains 260 bytes,
but its smallest valid readback stride is 512 bytes:

```ruby
width = 65
height = 2
bytes_per_row = WGPU::TextureFormat.aligned_bytes_per_row(width, :rgba8_unorm)
# => 512

pixels = queue.read_texture(
  source: { texture: texture },
  data_layout: { bytes_per_row: bytes_per_row, rows_per_image: height },
  size: { width: width, height: height }
)
```

The returned string includes row padding and has
`bytes_per_row * rows_per_image * depth_or_array_layers` bytes. Read only the
tight bytes of each row when processing pixels.

Both `Queue#read_texture` and `Queue#read_buffer` accept an optional `staging:`
buffer for repeated readbacks. It must be unmapped, belong to the same device,
be large enough for the full returned string, and include both `:map_read` and
`:copy_dst` usage. The helper unmaps caller-provided staging after each read but
does not release it, so the caller can reuse it and remains responsible for
releasing it. The queue uses its owning device when `device:` is omitted.
