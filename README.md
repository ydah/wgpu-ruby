# WGPU Ruby

Ruby bindings for [WebGPU](https://www.w3.org/TR/webgpu/) via [wgpu-native](https://github.com/gfx-rs/wgpu-native).

## Features

- WebGPU object bindings using Ruby-FFI, with an explicit [API coverage matrix](docs/api_coverage.md)
- GPU compute shaders (GPGPU)
- Cross-platform support (macOS, Linux, Windows)
- Automatic wgpu-native library download on gem install

## Requirements

- Ruby 3.2+
- Supported platforms (64-bit only):
  - macOS (x86_64, arm64)
  - Linux (x86_64, aarch64)
  - Windows (x86_64)

## Installation

Add to your Gemfile:

```ruby
gem 'wgpu'
```

Then run:

```bash
bundle install
```

Or install directly:

```bash
gem install wgpu
```

The wgpu-native library is automatically downloaded from GitHub Releases during installation.
See [Installation and native artifacts](docs/installation.md) for supported
artifacts, cache behavior, manual installation, and troubleshooting.

### Custom wgpu-native Build

To use a custom build of wgpu-native:

```bash
export WGPU_LIB_PATH=/path/to/libwgpu_native.so
```

## Usage

### Basic Setup

```ruby
require 'wgpu'

instance = WGPU::Instance.new
adapter = instance.request_adapter(power_preference: :high_performance)
device = adapter.request_device
queue = device.queue

puts "Using: #{adapter.info[:device]} (#{adapter.info[:backend_type]})"
```

### Compute Shader Example

```ruby
require 'wgpu'

shader_code = <<~WGSL
  @group(0) @binding(0) var<storage, read_write> data: array<f32>;

  @compute @workgroup_size(64)
  fn main(@builtin(global_invocation_id) id: vec3<u32>) {
    data[id.x] = data[id.x] * 2.0;
  }
WGSL

instance = WGPU::Instance.new
adapter = instance.request_adapter
device = adapter.request_device
queue = device.queue

# Create buffer with initial data
input_data = (0...256).map(&:to_f)
buffer = device.create_buffer(
  size: input_data.size * 4,
  usage: [:storage, :copy_src, :copy_dst],
  mapped_at_creation: true
)
buffer.mapped_range.write_floats(input_data)
buffer.unmap

# Create shader and pipeline
shader = device.create_shader_module(code: shader_code)

bind_group_layout = device.create_bind_group_layout(
  entries: [{ binding: 0, visibility: :compute, buffer: { type: :storage } }]
)

bind_group = device.create_bind_group(
  layout: bind_group_layout,
  entries: [{ binding: 0, buffer: buffer, offset: 0, size: buffer.size }]
)

pipeline_layout = device.create_pipeline_layout(bind_group_layouts: [bind_group_layout])
pipeline = device.create_compute_pipeline(
  layout: pipeline_layout,
  compute: { module: shader, entry_point: "main" }
)

# Execute compute pass
encoder = device.create_command_encoder
pass = encoder.begin_compute_pass
pass.set_pipeline(pipeline)
pass.set_bind_group(0, bind_group)
pass.dispatch_workgroups(input_data.size / 64)
pass.end_pass
queue.submit([encoder.finish])

# Read results
result = queue.read_buffer(buffer, device: device)
output_data = result.unpack("f*")

puts output_data[0, 10].inspect
# => [0.0, 2.0, 4.0, 6.0, 8.0, 10.0, 12.0, 14.0, 16.0, 18.0]
```

## Examples

See the [`examples/` guide](examples/README.md) for prerequisites, expected
results, and more complete examples:

Compute examples:
- `01_adapter_info.rb` - Query GPU adapter information
- `02_compute_basic.rb` - Basic compute shader
- `03_buffer_operations.rb` - Buffer read/write operations
- `04_matrix_multiply.rb` - GPU matrix multiplication
- `05_image_blur.rb` - Image processing with box filter
- `06_parallel_reduction.rb` - Parallel sum reduction

Headless validation examples:

- `12_headless_render.rb` - Offscreen triangle and pixel verification
- `13_error_handling.rb` - Typed, labeled validation errors
- `14_async_map.rb` - Async mapping through a forced GC cycle
- `15_timestamp_query.rb` - Feature-gated timestamp query resolution

Rendering examples (SDL3):
- `07_triangle.rb` - Basic triangle rendering
- `08_colored_quad.rb` - Indexed colored quad rendering
- `09_clear_color.rb` - Animated clear color
- `10_textured_quad.rb` - Textured quad rendering
- `11_rotating_cube.rb` - Rotating 3D cube with depth buffer

Run an example:

```bash
bundle exec ruby examples/02_compute_basic.rb
```

Rendering examples require SDL3 on your system:

```bash
# macOS
brew install sdl3

# Gemfile
gem "sdl3", "~> 1.0"
```

The core `wgpu` gem does not depend on SDL3. Only code that explicitly requires
`wgpu/window` needs the optional Ruby gem and system library.

## API Overview

### Core Objects

| Class | Description |
|-------|-------------|
| `WGPU::Instance` | Entry point for WebGPU |
| `WGPU::Adapter` | Represents a GPU adapter |
| `WGPU::Device` | Logical device for GPU operations |
| `WGPU::Queue` | Command submission queue |

### Resources

| Class | Description |
|-------|-------------|
| `WGPU::Buffer` | GPU buffer for data storage |
| `WGPU::Texture` | GPU texture |
| `WGPU::TextureView` | View into a texture |
| `WGPU::Sampler` | Texture sampling configuration |

### Pipeline

| Class | Description |
|-------|-------------|
| `WGPU::ShaderModule` | Compiled WGSL shader |
| `WGPU::ComputePipeline` | Compute shader pipeline |
| `WGPU::RenderPipeline` | Render pipeline |
| `WGPU::BindGroup` | Resource bindings for shaders |
| `WGPU::BindGroupLayout` | Layout definition for bind groups |
| `WGPU::PipelineLayout` | Pipeline layout definition |

### Commands

| Class | Description |
|-------|-------------|
| `WGPU::CommandEncoder` | Records GPU commands |
| `WGPU::CommandBuffer` | Encoded commands ready to submit |
| `WGPU::ComputePass` | Compute pass encoder |
| `WGPU::RenderPass` | Render pass encoder |

## Development

```bash
git clone https://github.com/ydah/wgpu-ruby.git
cd wgpu-ruby
bundle install
bundle exec rake spec
```

See [Resource lifetime](docs/resource_lifetime.md) before building long-running
applications, and use the [API coverage matrix](docs/api_coverage.md) to check
the current relationship to the WebGPU specification. The
[documentation index](docs/README.md) links the compute/rendering guides,
buffer/texture rules, async and error handling, troubleshooting, and release
operations.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ydah/wgpu-ruby.

## License

Licensed under either of

- [Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0)
- [MIT License](http://opensource.org/licenses/MIT)

at your option.

## References

- [WebGPU Specification](https://www.w3.org/TR/webgpu/)
- [WGSL Specification](https://www.w3.org/TR/WGSL/)
- [wgpu-native](https://github.com/gfx-rs/wgpu-native)
- [wgpu (Rust)](https://github.com/gfx-rs/wgpu)
