# Examples

The examples are executable specifications for the public API. Run them from
the repository root after `bundle install` and `bundle exec rake wgpu:install`.

## Compute and headless examples

These do not require SDL3 and are suitable for a GPU/lavapipe CI worker:

| Example | Purpose | Expected result |
|---|---|---|
| `01_adapter_info.rb` | Enumerate and inspect adapters | Prints at least one adapter and its capabilities. |
| `02_compute_basic.rb` | Double an f32 storage buffer | Prints doubled values and `SUCCESS`. |
| `03_buffer_operations.rb` | Exercise upload/copy/map/readback | Each operation prints the expected values. |
| `04_matrix_multiply.rb` | Multiply matrices in a compute shader | CPU and GPU results compare successfully. |
| `05_image_blur.rb` | Apply a box blur | Prints the processed image/result and succeeds. |
| `06_parallel_reduction.rb` | Sum values through repeated dispatch | GPU sum matches the expected sum. |
| `12_headless_render.rb` | Render without SDL3/surface | Center triangle pixel is red and corner clear pixel is blue. |
| `13_error_handling.rb` | Show labeled Ruby validation errors | Prints the typed error and passes. |
| `14_async_map.rb` | Map a copied buffer asynchronously | Prints `[10, 20, 30, 40]` after a GC cycle. |
| `15_timestamp_query.rb` | Resolve pass timestamps | Prints a non-negative tick delta, or an explicit unsupported skip. |
| `16_texture_readback.rb` | Read back a 65-pixel-wide texture with aligned reusable staging | Prints 260-byte tight/512-byte aligned strides and `SUCCESS`. |

Run all compute and headless examples:

```bash
bundle exec rake examples:ci
```

Set `WGPU_HEADLESS_OUTPUT=triangle.ppm` to save the headless render result.

## SDL3 rendering examples

These open a window and remain manual integration checks:

| Example | Purpose | Expected result |
|---|---|---|
| `07_triangle.rb` | Basic render pipeline | A colored triangle is visible. |
| `08_colored_quad.rb` | Vertex and index buffers | A colored quad is visible. |
| `09_clear_color.rb` | Animated clear pass and resize | The background follows the resized drawable. |
| `10_textured_quad.rb` | Texture upload and sampling | A checkerboard/textured quad is visible. |
| `11_rotating_cube.rb` | Uniforms and depth testing | A depth-tested cube rotates. |

Add `gem "sdl3", "~> 1.0"` to your application and install the SDL3 system
library before running these. Press Escape or close the window to exit.
