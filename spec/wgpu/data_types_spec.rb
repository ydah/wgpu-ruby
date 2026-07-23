# frozen_string_literal: true

RSpec.describe WGPU::DataTypes, :skip_gpu_check do
  {
    f32: [[1.5, -2.25], "e*"],
    f64: [[1.5, -2.25], "E*"],
    u32: [[0, 0xFFFFFFFF], "L<*"],
    i32: [[-1, 2], "l<*"],
    u16: [[0, 65_535], "S<*"],
    u8: [[0, 255], "C*"]
  }.each do |type, (values, format)|
    it "round-trips #{type}" do
      bytes = described_class.pack(values, type:)

      expect(bytes).to eq(values.pack(format))
      expect(described_class.unpack(bytes, type:)).to eq(values)
    end
  end

  it "preserves f32 as the default for Array data" do
    pointer, size = described_class.to_pointer([1.0, 2.0])

    expect(size).to eq(8)
    expect(pointer.read_bytes(size)).to eq([1.0, 2.0].pack("e*"))
  end

  it "lists supported types for invalid input" do
    expect { described_class.pack([1], type: :half) }.to raise_error(
      ArgumentError,
      /Unknown data type :half.*:f32.*:u8/
    )
  end

  it "validates WebGPU alignment before native calls" do
    expect(described_class.validate_alignment!(8, 8, name: "offset")).to eq(8)
    expect do
      described_class.validate_alignment!(4, 8, name: "offset")
    end.to raise_error(ArgumentError, /offset must be aligned to 8 bytes/)
  end

  it "supports typed mapped-range reads and writes" do
    pointer = FFI::MemoryPointer.new(:char, 8)
    range = WGPU::BufferMappedRange.new(pointer, 8)

    range.write_uint32s([1, 0xFFFFFFFF])

    expect(range.read_uint32s).to eq([1, 0xFFFFFFFF])
    expect { range.write_uint32s([1, 2, 3]) }.to raise_error(ArgumentError, /exceeds mapped range/)
  end

  it "rejects mapped-range reads and raw writes beyond the native allocation" do
    pointer = FFI::MemoryPointer.new(:char, 8)
    range = WGPU::BufferMappedRange.new(pointer, 8)

    expect { range.read_uint32s(3) }.to raise_error(ArgumentError, /exceeds mapped range/)
    expect { range.read_uint8s(-1) }.to raise_error(ArgumentError, /count must be non-negative/)
    expect { range.write_bytes("123456789") }.to raise_error(ArgumentError, /exceeds mapped range/)
  end

  it "rejects aligned map ranges beyond the buffer boundary" do
    buffer = WGPU::Buffer.allocate
    buffer.instance_variable_set(:@size, 16)

    expect(buffer.send(:validate_map_range!, 8, 8)).to eq([8, 8])
    expect do
      buffer.send(:validate_map_range!, 8, 12)
    end.to raise_error(ArgumentError, /exceeds buffer size 16/)
    expect do
      buffer.send(:validate_map_range!, 24, 4)
    end.to raise_error(ArgumentError, /exceeds buffer size 16/)
  end
end
