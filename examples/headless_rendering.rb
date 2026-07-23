# frozen_string_literal: true

require_relative "../lib/wgpu"

module HeadlessRendering
  WIDTH = 64
  HEIGHT = 64
  FORMAT = :rgba8_unorm
  SHADER = <<~WGSL
    @vertex
    fn vs_main(@builtin(vertex_index) index: u32) -> @builtin(position) vec4<f32> {
      var positions = array<vec2<f32>, 3>(
        vec2<f32>(-0.8, -0.8),
        vec2<f32>( 0.8, -0.8),
        vec2<f32>( 0.0,  0.8)
      );
      return vec4<f32>(positions[index], 0.0, 1.0);
    }

    @fragment
    fn fs_main() -> @location(0) vec4<f32> {
      return vec4<f32>(1.0, 0.0, 0.0, 1.0);
    }
  WGSL

  module_function

  def run(output_path: nil)
    resources = []
    instance = WGPU::Instance.new
    adapter = instance.request_adapter(timeout: 10)
    device = adapter.request_device(timeout: 10)

    texture = device.create_texture(
      label: "headless target",
      size: { width: WIDTH, height: HEIGHT },
      format: FORMAT,
      usage: %i[render_attachment copy_src]
    )
    resources << texture
    view = texture.create_view
    resources << view
    shader = device.create_shader_module(label: "headless triangle", code: SHADER)
    resources << shader
    pipeline = device.create_render_pipeline(
      label: "headless pipeline",
      layout: :auto,
      vertex: { module: shader, entry_point: "vs_main" },
      fragment: {
        module: shader,
        entry_point: "fs_main",
        targets: [{ format: FORMAT }]
      }
    )
    resources << pipeline

    encoder = device.create_command_encoder(label: "headless encoder")
    resources << encoder
    encoder.begin_render_pass(
      color_attachments: [{
        view: view,
        load_op: :clear,
        store_op: :store,
        clear_value: { r: 0.0, g: 0.0, b: 1.0, a: 1.0 }
      }]
    ) do |pass|
      pass.set_pipeline(pipeline)
      pass.draw(3)
    end
    command_buffer = encoder.finish
    resources << command_buffer
    device.queue.submit(command_buffer)

    bytes_per_row = WGPU::TextureFormat.aligned_bytes_per_row(WIDTH, FORMAT)
    pixels = device.queue.read_texture(
      source: { texture: texture },
      data_layout: { bytes_per_row: bytes_per_row, rows_per_image: HEIGHT },
      size: { width: WIDTH, height: HEIGHT }
    )
    write_ppm(output_path, pixels, bytes_per_row) if output_path

    {
      center: pixel_at(pixels, WIDTH / 2, HEIGHT / 2, bytes_per_row),
      corner: pixel_at(pixels, 0, 0, bytes_per_row),
      pixels: pixels
    }
  ensure
    resources&.reverse_each { |resource| resource.release unless resource.released? }
    device&.release unless device&.released?
    adapter&.release unless adapter&.released?
    instance&.release unless instance&.released?
  end

  def pixel_at(pixels, x, y, bytes_per_row)
    offset = (y * bytes_per_row) + (x * 4)
    pixels.byteslice(offset, 4).bytes
  end

  def write_ppm(path, pixels, bytes_per_row)
    rgb = String.new(capacity: WIDTH * HEIGHT * 3, encoding: Encoding::BINARY)
    HEIGHT.times do |y|
      row = pixels.byteslice(y * bytes_per_row, WIDTH * 4)
      WIDTH.times { |x| rgb << row.byteslice(x * 4, 3) }
    end
    File.binwrite(path, "P6\n#{WIDTH} #{HEIGHT}\n255\n#{rgb}")
  end
end
