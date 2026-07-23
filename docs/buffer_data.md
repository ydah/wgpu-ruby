# Buffer data

Ruby Arrays passed to buffer APIs use 32-bit floats by default, preserving the
original wgpu-ruby behavior. Pass `type:` to use another WebGPU scalar
representation:

| `type:` | Encoding | Bytes |
|---|---|---:|
| `:f32` | IEEE 754 float | 4 |
| `:f64` | IEEE 754 double | 8 |
| `:u32` | unsigned integer | 4 |
| `:i32` | signed integer | 4 |
| `:u16` | unsigned integer | 2 |
| `:u8` | unsigned integer | 1 |

The keyword is accepted by `Device#create_buffer_with_data`, `Buffer#write`,
`Buffer#write_mapped`, `Queue#write_buffer`, and `Queue#write_texture`.
Strings remain raw bytes and `FFI::Pointer` values remain unconverted.

```ruby
buffer = device.create_buffer_with_data(
  data: [1, 2, 3, 4],
  type: :u32,
  usage: %i[storage copy_src]
)

queue.write_buffer(buffer, 0, [10, 20], type: :u32)
```

`BufferMappedRange#read` and `#write` expose the same `type:` keyword. The
existing `read_floats` / `write_floats` methods remain aliases for the `:f32`
path. Typed convenience pairs are also available for float64, uint32, int32,
uint16, and uint8.

WebGPU alignment errors are reported before entering FFI: queue write offsets
and sizes must be multiples of 4 bytes; mapped offsets must be multiples of 8
bytes and mapped sizes multiples of 4 bytes.
