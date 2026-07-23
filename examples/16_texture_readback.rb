# frozen_string_literal: true

# Purpose: read back a texture whose tight row is not 256-byte aligned.
# APIs: TextureFormat row helpers, Queue#write_texture/#read_texture, reusable staging.
# Expected: verifies two readbacks and prints aligned stride details followed by SUCCESS.

require_relative "../lib/wgpu"

WIDTH = 65
HEIGHT = 3
FORMAT = :rgba8_unorm

begin
  resources = []
  instance = WGPU::Instance.new
  adapter = instance.request_adapter(timeout: 10)
  device = adapter.request_device(timeout: 10)
  queue = device.queue

  tight_bytes_per_row = WGPU::TextureFormat.bytes_per_row(WIDTH, FORMAT)
  bytes_per_row = WGPU::TextureFormat.aligned_bytes_per_row(WIDTH, FORMAT)
  padding = "\0" * (bytes_per_row - tight_bytes_per_row)
  rows = HEIGHT.times.map do |y|
    pixels = WIDTH.times.map do |x|
      [x, y * 64, 255 - x, 255].pack("C4")
    end.join
    pixels + padding
  end
  upload = rows.join.b

  texture = device.create_texture(
    label: "unaligned-width readback",
    size: { width: WIDTH, height: HEIGHT },
    format: FORMAT,
    usage: %i[copy_dst copy_src]
  )
  resources << texture
  staging = device.create_buffer(
    label: "reusable texture readback staging",
    size: bytes_per_row * HEIGHT,
    usage: %i[map_read copy_dst]
  )
  resources << staging

  queue.write_texture(
    destination: { texture: texture },
    data: upload,
    data_layout: { bytes_per_row: bytes_per_row, rows_per_image: HEIGHT },
    size: { width: WIDTH, height: HEIGHT },
    type: :u8
  )

  2.times do
    readback = queue.read_texture(
      source: { texture: texture },
      data_layout: { bytes_per_row: bytes_per_row, rows_per_image: HEIGHT },
      size: { width: WIDTH, height: HEIGHT },
      staging: staging
    )

    HEIGHT.times do |y|
      actual = readback.byteslice(y * bytes_per_row, tight_bytes_per_row)
      expected = upload.byteslice(y * bytes_per_row, tight_bytes_per_row)
      raise "texture readback mismatch on row #{y}" unless actual == expected
    end
  end

  puts "width=#{WIDTH}, tight_bytes_per_row=#{tight_bytes_per_row}, aligned_bytes_per_row=#{bytes_per_row}"
  puts "SUCCESS: unaligned-width texture readback with reusable staging"
ensure
  resources&.reverse_each { |resource| resource.release unless resource.released? }
  device&.release unless device&.released?
  adapter&.release unless adapter&.released?
  instance&.release unless instance&.released?
end
