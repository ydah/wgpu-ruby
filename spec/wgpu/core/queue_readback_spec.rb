# frozen_string_literal: true

RSpec.describe WGPU::Queue do
  subject(:queue) do
    described_class.allocate.tap do |value|
      value.instance_variable_set(:@handle, FFI::Pointer.new(1))
      value.instance_variable_set(:@device, device)
    end
  end

  let(:device) { instance_double(WGPU::Device) }
  let(:readback_usage) do
    WGPU::Native::BufferUsage.fetch(:map_read) |
      WGPU::Native::BufferUsage.fetch(:copy_dst)
  end

  describe "#read_texture" do
    it "reports the aligned minimum bytes_per_row" do
      texture = instance_double(WGPU::Texture, format: :rgba8_unorm)

      expect do
        queue.read_texture(
          source: { texture: texture },
          data_layout: { bytes_per_row: 256 },
          size: { width: 65, height: 2 }
        )
      end.to raise_error(
        ArgumentError,
        /at least 512.*width 65.*tight row is 260 bytes/
      )
    end

    it "rejects caller-provided staging buffers that are too small" do
      texture = instance_double(WGPU::Texture, format: :rgba8_unorm)
      staging = instance_double(
        WGPU::Buffer,
        size: 511,
        usage: readback_usage,
        map_state: :unmapped
      )

      expect do
        queue.read_texture(
          source: { texture: texture },
          data_layout: { bytes_per_row: 256 },
          size: { width: 64, height: 2 },
          staging: staging
        )
      end.to raise_error(ArgumentError, /size must be at least 512 bytes/)
    end
  end

  describe "#read_buffer" do
    let(:source) { instance_double(WGPU::Buffer, size: 16) }
    let(:command_buffer) { instance_double(WGPU::CommandBuffer) }
    let(:encoder) { instance_double(WGPU::CommandEncoder) }

    before do
      allow(WGPU::CommandEncoder).to receive(:new).with(device).and_return(encoder)
      allow(encoder).to receive(:copy_buffer_to_buffer)
      allow(encoder).to receive(:finish).and_return(command_buffer)
      allow(encoder).to receive(:release)
      allow(command_buffer).to receive(:release)
      allow(queue).to receive(:submit)
    end

    it "rejects staging without both readback usage flags" do
      staging = instance_double(
        WGPU::Buffer,
        size: 16,
        usage: WGPU::Native::BufferUsage.fetch(:map_read),
        map_state: :unmapped
      )

      expect do
        queue.read_buffer(source, staging: staging)
      end.to raise_error(ArgumentError, /must include :map_read and :copy_dst/)

      expect(WGPU::CommandEncoder).not_to have_received(:new)
    end

    it "rejects mapped staging without changing caller-owned state" do
      staging = instance_double(
        WGPU::Buffer,
        size: 16,
        usage: readback_usage,
        map_state: :mapped
      )
      allow(staging).to receive(:unmap)
      allow(staging).to receive(:release)

      expect do
        queue.read_buffer(source, staging: staging)
      end.to raise_error(ArgumentError, /must be unmapped/)

      expect(staging).not_to have_received(:unmap)
      expect(staging).not_to have_received(:release)
    end

    it "does not release a reusable caller-provided staging buffer" do
      map_state = :unmapped
      staging = instance_double(WGPU::Buffer, size: 16, usage: readback_usage)
      allow(staging).to receive(:map_state) { map_state }
      allow(staging).to receive(:map_sync) { map_state = :mapped }
      allow(staging).to receive(:read_mapped_data).with(size: 16).and_return("readback".b)
      allow(staging).to receive(:unmap) { map_state = :unmapped }
      allow(staging).to receive(:release)

      2.times do
        expect(queue.read_buffer(source, staging: staging)).to eq("readback".b)
      end

      expect(WGPU::CommandEncoder).to have_received(:new).with(device).twice
      expect(staging).to have_received(:unmap).twice
      expect(staging).not_to have_received(:release)
    end

    it "finishes all cleanup steps and preserves the read failure" do
      map_state = :unmapped
      staging = instance_double(WGPU::Buffer, size: 16, usage: readback_usage)
      allow(WGPU::Buffer).to receive(:new).and_return(staging)
      allow(staging).to receive(:map_state) { map_state }
      allow(staging).to receive(:map_sync) { map_state = :mapped }
      allow(staging).to receive(:read_mapped_data).and_raise("read failed")
      allow(staging).to receive(:unmap).and_raise("unmap failed")
      allow(staging).to receive(:release)
      allow(command_buffer).to receive(:release).and_raise("command buffer release failed")
      allow(encoder).to receive(:release).and_raise("encoder release failed")

      expect do
        queue.read_buffer(source)
      end.to raise_error(RuntimeError, "read failed")

      expect(staging).to have_received(:unmap)
      expect(command_buffer).to have_received(:release)
      expect(encoder).to have_received(:release)
      expect(staging).to have_received(:release)
    end
  end
end
