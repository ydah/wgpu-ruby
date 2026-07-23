# frozen_string_literal: true

RSpec.describe WGPU::Queue, :gpu do
  let(:instance) { WGPU::Instance.new }
  let(:adapter) { instance.request_adapter }
  let(:device) { adapter.request_device }
  let(:queue) { device.queue }

  after do
    device.release
    adapter.release
    instance.release
  end

  describe "#submit" do
    it "submits command buffers" do
      encoder = device.create_command_encoder
      command_buffer = encoder.finish
      expect { queue.submit([command_buffer]) }.not_to raise_error
    end

    it "accepts a single command buffer" do
      encoder = device.create_command_encoder
      command_buffer = encoder.finish
      expect { queue.submit(command_buffer) }.not_to raise_error
    end
  end

  describe "#write_buffer" do
    it "writes float data to buffer" do
      buffer = device.create_buffer(size: 64, usage: [:storage, :copy_dst])
      data = [1.0, 2.0, 3.0, 4.0]
      expect { queue.write_buffer(buffer, 0, data) }.not_to raise_error
      buffer.release
    end

    it "writes string data to buffer" do
      buffer = device.create_buffer(size: 64, usage: [:storage, :copy_dst])
      data = "hellowld"
      expect { queue.write_buffer(buffer, 0, data) }.not_to raise_error
      buffer.release
    end

    it "writes with offset" do
      buffer = device.create_buffer(size: 64, usage: [:storage, :copy_dst])
      data = [1.0, 2.0]
      expect { queue.write_buffer(buffer, 16, data) }.not_to raise_error
      buffer.release
    end

    it "writes with data_offset and size" do
      buffer = device.create_buffer(size: 64, usage: [:storage, :copy_dst])
      data = "abcdefgh"
      expect do
        queue.write_buffer(buffer, 0, data, data_offset: 2, size: 4)
      end.not_to raise_error
      buffer.release
    end
  end

  describe "#write_texture" do
    let(:texture) do
      device.create_texture(
        size: { width: 64, height: 64 },
        format: :rgba8_unorm,
        usage: [:texture_binding, :copy_dst]
      )
    end

    after { texture.release }

    it "writes data to a texture" do
      data = "\xFF" * (64 * 64 * 4)
      expect do
        queue.write_texture(
          destination: { texture: texture },
          data: data,
          data_layout: { bytes_per_row: 64 * 4 },
          size: { width: 64, height: 64 }
        )
      end.not_to raise_error
    end

    it "writes to a texture region with origin" do
      data = "\xFF" * (256 * 32)
      expect do
        queue.write_texture(
          destination: { texture: texture, origin: { x: 0, y: 0, z: 0 } },
          data: data,
          data_layout: { bytes_per_row: 256 },
          size: { width: 64, height: 32 }
        )
      end.not_to raise_error
    end

    it "accepts array-style size" do
      data = "\xFF" * (64 * 64 * 4)
      expect do
        queue.write_texture(
          destination: { texture: texture },
          data: data,
          data_layout: { bytes_per_row: 64 * 4 },
          size: [64, 64, 1]
        )
      end.not_to raise_error
    end
  end

  describe "#read_buffer" do
    it "reads data from a buffer" do
      input_data = [1.0, 2.0, 3.0, 4.0]
      buffer = device.create_buffer_with_data(
        data: input_data,
        usage: [:storage, :copy_src]
      )
      device.poll(wait: true)

      result = queue.read_buffer(buffer, device: device)
      expect(result).to be_a(String)
      expect(result.bytesize).to eq(16)
      buffer.release
    end

    it "reads with offset and size" do
      input_data = [1.0, 2.0, 3.0, 4.0]
      buffer = device.create_buffer_with_data(
        data: input_data,
        usage: [:storage, :copy_src]
      )
      device.poll(wait: true)

      result = queue.read_buffer(buffer, offset: 4, size: 8, device: device)
      expect(result.bytesize).to eq(8)
      buffer.release
    end
  end

  describe "#read_texture" do
    it "reads data from a texture" do
      texture = device.create_texture(
        size: { width: 64, height: 64 },
        format: :rgba8_unorm,
        usage: [:texture_binding, :copy_dst, :copy_src]
      )

      data = "\xFF\x00\x00\xFF" * (64 * 64)
      queue.write_texture(
        destination: { texture: texture },
        data: data,
        data_layout: { bytes_per_row: 64 * 4 },
        size: { width: 64, height: 64 }
      )
      device.poll(wait: true)

      result = queue.read_texture(
        source: { texture: texture },
        data_layout: { bytes_per_row: 256 },
        size: { width: 64, height: 64 },
        device: device
      )
      expect(result).to be_a(String)
      expect(result.bytesize).to eq(256 * 64)
      texture.release
    end
  end

  describe "#on_submitted_work_done_async" do
    it "returns async task" do
      encoder = device.create_command_encoder
      queue.submit([encoder.finish])
      task = queue.on_submitted_work_done_async(device: device)
      expect(task).to be_a(WGPU::AsyncTask)
      expect(task.value).to be_a(Symbol)
    end
  end
end
