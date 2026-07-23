# frozen_string_literal: true

RSpec.describe WGPU::TextureFormat, :skip_gpu_check do
  it "reports plain format block sizes" do
    expect(described_class.block_size(:r8_unorm)).to eq(1)
    expect(described_class.block_size(:rgba8_unorm)).to eq(4)
    expect(described_class.block_size(:rgba16_float)).to eq(8)
    expect(described_class.block_size(:rgba32_float)).to eq(16)
  end

  it "reports compressed block dimensions and sizes" do
    expect(described_class.block_info(:bc1_rgba_unorm)).to eq([4, 4, 8])
    expect(described_class.block_info(:bc7_rgba_unorm)).to eq([4, 4, 16])
    expect(described_class.block_info(:astc_10x6_unorm)).to eq([10, 6, 16])
  end

  it "calculates tight and 256-byte-aligned rows" do
    expect(described_class.bytes_per_row(65, :rgba8_unorm)).to eq(260)
    expect(described_class.aligned_bytes_per_row(65, :rgba8_unorm)).to eq(512)
    expect(described_class.aligned_bytes_per_row(64, :rgba8_unorm)).to eq(256)
  end

  it "requires a single aspect for combined depth-stencil copies" do
    expect(described_class.block_size(:depth32_float_stencil8, aspect: :depth_only)).to eq(4)
    expect(described_class.block_size(:depth32_float_stencil8, aspect: :stencil_only)).to eq(1)
    expect do
      described_class.block_size(:depth32_float_stencil8)
    end.to raise_error(ArgumentError, /require :depth_only or :stencil_only/)
  end

  it "rejects formats without a portable copy footprint" do
    expect do
      described_class.block_size(:depth24_plus)
    end.to raise_error(ArgumentError, /no portable texel block copy footprint/)
  end

  it "covers every color format exposed by the pinned enum" do
    excluded = %i[undefined depth24_plus depth24_plus_stencil8 depth32_float_stencil8]
    formats = WGPU::Native::TextureFormat.to_h.keys - excluded

    expect { formats.each { |format| described_class.block_info(format) } }.not_to raise_error
  end
end
