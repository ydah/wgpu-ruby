# frozen_string_literal: true

RSpec.describe WGPU::Buffer, :gpu do
  let(:instance) { WGPU::Instance.new }
  let(:adapter) { instance.request_adapter }
  let(:device) { adapter.request_device }

  after do
    device.release
    adapter.release
    instance.release
  end

  describe "#initialize" do
    it "creates a buffer with specified size" do
      buffer = device.create_buffer(size: 256, usage: :storage)
      expect(buffer).to be_a(WGPU::Buffer)
      expect(buffer.size).to eq(256)
      buffer.release
    end

    it "creates a buffer with multiple usages" do
      buffer = device.create_buffer(size: 256, usage: [:storage, :copy_src, :copy_dst])
      expect(buffer).to be_a(WGPU::Buffer)
      buffer.release
    end

    it "creates a buffer with label" do
      buffer = device.create_buffer(label: "test buffer", size: 256, usage: :storage)
      expect(buffer.handle).not_to be_null
      buffer.release
    end

    it "creates a mapped buffer" do
      buffer = device.create_buffer(size: 256, usage: :map_read, mapped_at_creation: true)
      expect(buffer).to be_a(WGPU::Buffer)
      buffer.unmap
      buffer.release
    end
  end

  describe "#size" do
    it "returns the buffer size" do
      buffer = device.create_buffer(size: 512, usage: :storage)
      expect(buffer.size).to eq(512)
      buffer.release
    end
  end

  describe "#usage" do
    it "returns the buffer usage flags" do
      buffer = device.create_buffer(size: 256, usage: [:storage, :copy_src])
      expect(buffer.usage).to be_a(Integer)
      expect(buffer.usage).to be > 0
      buffer.release
    end
  end

  describe "#mapped_range" do
    it "returns mapped range for mapped buffer" do
      buffer = device.create_buffer(size: 64, usage: :map_read, mapped_at_creation: true)
      range = buffer.mapped_range
      expect(range).to be_a(WGPU::BufferMappedRange)
      buffer.unmap
      buffer.release
    end
  end

  describe "#unmap" do
    it "unmaps a mapped buffer" do
      buffer = device.create_buffer(size: 64, usage: :map_read, mapped_at_creation: true)
      expect { buffer.unmap }.not_to raise_error
      buffer.release
    end
  end

  describe "#map_async" do
    it "maps buffer for reading" do
      buffer = device.create_buffer(size: 64, usage: [:map_read, :copy_dst])
      task = buffer.map_async(:read)
      expect(task).to be_a(WGPU::AsyncTask)
      expect(task.value).to eq(true)
      buffer.unmap
      buffer.release
    end

    it "retains callbacks across GC stress" do
      buffers = Array.new(32) do
        device.create_buffer(size: 64, usage: %i[map_read copy_dst])
      end
      tasks = buffers.map { |buffer| buffer.map_async(:read) }

      3.times { GC.start }
      expect(tasks.map(&:value)).to all(eq(true))
    ensure
      buffers&.each do |buffer|
        buffer.unmap if buffer.map_state == :mapped
        buffer.release
      end
    end
  end

  describe "#read_mapped_data" do
    it "reads data from mapped buffer" do
      source = device.create_buffer_with_data(data: [1.0, 2.0, 3.0, 4.0], usage: [:storage, :copy_src])
      dest = device.create_buffer(size: 16, usage: [:map_read, :copy_dst])

      encoder = device.create_command_encoder
      encoder.copy_buffer_to_buffer(source: source, destination: dest, size: 16)
      device.queue.submit([encoder.finish])
      device.poll(wait: true)

      dest.map_sync(:read)
      data = dest.read_mapped_data
      expect(data).to be_a(String)
      expect(data.bytesize).to eq(16)
      dest.unmap

      source.release
      dest.release
    end
  end

  describe "#destroy" do
    it "destroys the buffer" do
      buffer = device.create_buffer(size: 256, usage: :storage)
      expect { buffer.destroy }.not_to raise_error
    end
  end

  describe "#release" do
    it "releases the buffer" do
      buffer = device.create_buffer(size: 256, usage: :storage)
      buffer.release
      expect(buffer.handle).to be_null
    end

    it "can be called multiple times" do
      buffer = device.create_buffer(size: 256, usage: :storage)
      buffer.release
      expect { buffer.release }.not_to raise_error
    end
  end
end

RSpec.describe WGPU::BufferMappedRange, :gpu do
  let(:instance) { WGPU::Instance.new }
  let(:adapter) { instance.request_adapter }
  let(:device) { adapter.request_device }

  after do
    device.release
    adapter.release
    instance.release
  end

  describe "#write_bytes" do
    it "writes bytes to the mapped range" do
      buffer = device.create_buffer(size: 64, usage: [:storage, :copy_src], mapped_at_creation: true)
      range = buffer.mapped_range
      expect { range.write_bytes("test data!12") }.not_to raise_error
      buffer.unmap
      buffer.release
    end
  end

  describe "#write_floats" do
    it "writes float array to the mapped range" do
      buffer = device.create_buffer(size: 64, usage: [:storage, :copy_src], mapped_at_creation: true)
      range = buffer.mapped_range
      expect { range.write_floats([1.0, 2.0, 3.0, 4.0]) }.not_to raise_error
      buffer.unmap
      buffer.release
    end
  end

  describe "#read_bytes" do
    it "reads bytes from the mapped range" do
      buffer = device.create_buffer(size: 64, usage: [:map_read, :copy_dst])
      buffer.map_sync(:read)
      range = buffer.mapped_range
      data = range.read_bytes
      expect(data).to be_a(String)
      expect(data.bytesize).to eq(64)
      buffer.unmap
      buffer.release
    end
  end

  describe "#read_floats" do
    it "reads float array from the mapped range" do
      source = device.create_buffer_with_data(data: [1.0, 2.0, 3.0, 4.0], usage: [:storage, :copy_src])
      dest = device.create_buffer(size: 16, usage: [:map_read, :copy_dst])

      encoder = device.create_command_encoder
      encoder.copy_buffer_to_buffer(source: source, destination: dest, size: 16)
      device.queue.submit([encoder.finish])
      device.poll(wait: true)

      dest.map_sync(:read)
      range = dest.mapped_range
      floats = range.read_floats
      expect(floats).to be_an(Array)
      expect(floats.size).to eq(4)
      dest.unmap

      source.release
      dest.release
    end
  end
end
