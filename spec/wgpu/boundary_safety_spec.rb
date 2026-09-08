# frozen_string_literal: true

RSpec.describe "native resource boundaries", :skip_gpu_check do
  def resource(klass, **state)
    object = klass.allocate
    object.instance_variable_set(:@handle, FFI::Pointer.new(1))
    state.each { |key, value| object.instance_variable_set(:"@#{key}", value) }
    object
  end

  let(:buffer) do
    resource(WGPU::Buffer, size: 256, mapped: true, map_state: :mapped,
      mapped_offset: 128, mapped_size: 128, map_generation: 1)
  end
  let(:encoder) { resource(WGPU::CommandEncoder) }

  it "forbids copying all native resource owners" do
    WGPU.constants.filter_map { |name| WGPU.const_get(name) }.select do |value|
      value.is_a?(Class) && value < WGPU::NativeResource
    end.each do |klass|
      object = resource(klass)
      expect { object.dup }.to raise_error(TypeError, /cannot be copied/)
      expect { object.clone }.to raise_error(TypeError, /cannot be copied/)
    end
  end

  it "rejects released and wrongly typed arguments before copying" do
    expect(WGPU::Native).not_to receive(:wgpuCommandEncoderCopyBufferToBuffer)
    source = resource(WGPU::Buffer, released: true)
    expect do
      encoder.copy_buffer_to_buffer(source: source, destination: buffer, size: 4)
    end.to raise_error(WGPU::ResourceError, /released/)
    expect do
      encoder.copy_buffer_to_buffer(source: resource(WGPU::Texture), destination: buffer, size: 4)
    end.to raise_error(TypeError, /WGPU::Buffer/)
  end

  it "validates zero-length clears without forwarding them to native code" do
    expect(WGPU::Native).not_to receive(:wgpuCommandEncoderClearBuffer)
    encoder.clear_buffer(buffer, size: 0)
    encoder.clear_buffer(buffer, offset: 256)
    expect { encoder.clear_buffer(buffer, offset: 260, size: 0) }.to raise_error(ArgumentError)
    expect { encoder.clear_buffer(buffer, offset: 2, size: 0) }.to raise_error(ArgumentError)
    expect { encoder.clear_buffer(buffer, size: -4) }.to raise_error(ArgumentError)
  end

  it "checks the actual mapping before any native pointer acquisition" do
    expect(WGPU::Native).not_to receive(:wgpuBufferGetMappedRange)
    expect(WGPU::Native).not_to receive(:wgpuBufferGetConstMappedRange)
    expect { buffer.mapped_range(offset: 0, size: 8) }.to raise_error(WGPU::BufferError, /outside/)
    expect { buffer.read_mapped_data(offset: 0, size: 8) }.to raise_error(WGPU::BufferError, /outside/)
    expect { buffer.write_mapped([1, 2], offset: 0) }.to raise_error(WGPU::BufferError, /outside/)
  end

  [:unmap, :destroy, :release].each do |operation|
    it "invalidates every mapped access after #{operation}, including after remapping" do
      pointer = FFI::MemoryPointer.new(:char, 8)
      allow(WGPU::Native).to receive(:wgpuBufferGetMappedRange).and_return(pointer)
      allow(WGPU::Native).to receive({ unmap: :wgpuBufferUnmap, destroy: :wgpuBufferDestroy,
                                      release: :wgpuBufferRelease }.fetch(operation))
      view = buffer.mapped_range(offset: 128, size: 8)
      view.write_uint32s([1, 2])
      expect(view.read_uint32s).to eq([1, 2])
      buffer.public_send(operation)
      # Even a new mapping cannot revive a view from the previous generation.
      buffer.instance_variable_set(:@mapped, true) unless operation == :release
      expect { view.read_bytes }.to raise_error(WGPU::BufferError, /no longer valid/)
      expect { view.read_uint32s }.to raise_error(WGPU::BufferError, /no longer valid/)
      expect { view.write_bytes("1234") }.to raise_error(WGPU::BufferError, /no longer valid/)
      expect { view.write_uint32s([3]) }.to raise_error(WGPU::BufferError, /no longer valid/)
    end
  end
end
