# frozen_string_literal: true

RSpec.describe WGPU::CommandBuffer, :gpu do
  let(:instance) { WGPU::Instance.new }
  let(:adapter) { instance.request_adapter }
  let(:device) { adapter.request_device }

  after do
    device.release
    adapter.release
    instance.release
  end

  describe "#initialize" do
    it "is created from command encoder finish" do
      encoder = device.create_command_encoder
      buffer = encoder.finish
      expect(buffer).to be_a(WGPU::CommandBuffer)
      expect(buffer.handle).not_to be_null
    end

    it "is created with label" do
      encoder = device.create_command_encoder
      buffer = encoder.finish(label: "test command buffer")
      expect(buffer).to be_a(WGPU::CommandBuffer)
      expect(buffer.handle).not_to be_null
    end
  end

  describe "#release" do
    it "releases the command buffer" do
      encoder = device.create_command_encoder
      buffer = encoder.finish
      buffer.release
      expect(buffer.handle).to be_null
    end

    it "can be called multiple times" do
      encoder = device.create_command_encoder
      buffer = encoder.finish
      buffer.release
      expect { buffer.release }.not_to raise_error
    end
  end

  describe "submission" do
    it "can be submitted to queue" do
      encoder = device.create_command_encoder
      buffer = encoder.finish
      expect { device.queue.submit([buffer]) }.not_to raise_error
    end

    it "can submit multiple command buffers" do
      encoder1 = device.create_command_encoder
      buffer1 = encoder1.finish

      encoder2 = device.create_command_encoder
      buffer2 = encoder2.finish

      expect { device.queue.submit([buffer1, buffer2]) }.not_to raise_error
    end

    it "can submit command buffer with recorded commands" do
      source = device.create_buffer_with_data(data: [1.0, 2.0, 3.0, 4.0], usage: [:storage, :copy_src])
      dest = device.create_buffer(size: 16, usage: [:storage, :copy_dst])

      encoder = device.create_command_encoder
      encoder.copy_buffer_to_buffer(source: source, destination: dest, size: 16)
      buffer = encoder.finish

      expect { device.queue.submit([buffer]) }.not_to raise_error

      source.release
      dest.release
    end
  end
end
