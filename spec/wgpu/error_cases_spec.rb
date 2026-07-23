# frozen_string_literal: true

RSpec.describe "Error handling", :gpu do
  let(:instance) { WGPU::Instance.new }
  let(:adapter) { instance.request_adapter }
  let(:device) { adapter.request_device }

  after do
    device.release
    adapter.release
    instance.release
  end

  describe WGPU::CommandEncoder do
    describe "#finish" do
      it "raises CommandError when finished twice" do
        encoder = device.create_command_encoder
        encoder.finish
        expect { encoder.finish }.to raise_error(WGPU::CommandError)
      end
    end

    describe "#begin_render_pass" do
      it "raises CommandError when encoder is already finished" do
        encoder = device.create_command_encoder
        encoder.finish
        expect { encoder.begin_render_pass(color_attachments: []) }.to raise_error(WGPU::CommandError)
      end
    end

    describe "#begin_compute_pass" do
      it "raises CommandError when encoder is already finished" do
        encoder = device.create_command_encoder
        encoder.finish
        expect { encoder.begin_compute_pass }.to raise_error(WGPU::CommandError)
      end
    end

    describe "#copy_buffer_to_buffer" do
      it "raises CommandError when encoder is already finished" do
        source = device.create_buffer(size: 16, usage: [:storage, :copy_src])
        dest = device.create_buffer(size: 16, usage: [:storage, :copy_dst])

        encoder = device.create_command_encoder
        encoder.finish
        expect do
          encoder.copy_buffer_to_buffer(source: source, destination: dest, size: 16)
        end.to raise_error(WGPU::CommandError)

        source.release
        dest.release
      end
    end
  end

  describe WGPU::Buffer do
    describe "#mapped_range" do
      it "raises BufferError when buffer is not mapped" do
        buffer = device.create_buffer(size: 64, usage: [:storage, :copy_src])
        expect { buffer.mapped_range }.to raise_error(WGPU::BufferError)
        buffer.release
      end
    end

    it "includes the operation and label for invalid usage" do
      expect do
        device.create_buffer(label: "bad upload", size: 64, usage: :not_a_usage)
      end.to raise_error(WGPU::BufferError, /create buffer.*bad upload.*not_a_usage/)
    end

    it "keeps a user error scope intact around an internally scoped creation" do
      device.push_error_scope(:validation)

      expect do
        device.create_buffer(
          label: "too large",
          size: device.limits.fetch(:max_buffer_size) + 4,
          usage: :storage
        )
      end.to raise_error(WGPU::BufferError, /create buffer.*too large/)

      expect(device.pop_error_scope.fetch(:type)).to eq(:no_error)
    end
  end

  describe "device callbacks" do
    it "dispatches uncaptured validation errors to the registered handler" do
      errors = []
      buffer = device.create_buffer(size: 4, usage: :copy_dst)
      device.on_uncaptured_error { |error| errors << error }

      device.queue.write_buffer(buffer, 8, "\0\0\0\0", type: :u8)
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 1
      while errors.empty? && Process.clock_gettime(Process::CLOCK_MONOTONIC) < deadline
        instance.process_events
      end

      expect(errors.first).to be_a(WGPU::GPUError)
      expect(errors.first.type).to eq(:validation)
    ensure
      buffer&.release
    end
  end

  describe WGPU::ShaderModule do
    it "raises ShaderError for invalid WGSL code" do
      expect do
        device.create_shader_module(code: "invalid wgsl code here")
      end.to raise_error(WGPU::ShaderError)
    end

    it "raises ShaderError for syntax error in shader code" do
      expect do
        device.create_shader_module(code: "@compute fn main() { let x = ;}")
      end.to raise_error(WGPU::ShaderError)
    end
  end

  describe WGPU::Instance do
    describe "#release" do
      it "sets handle to null after release" do
        inst = WGPU::Instance.new
        inst.release
        expect(inst.handle).to be_null
      end

      it "is safe to call release multiple times" do
        inst = WGPU::Instance.new
        inst.release
        expect { inst.release }.not_to raise_error
      end
    end
  end

  describe WGPU::Adapter do
    describe "#release" do
      it "sets handle to null after release" do
        inst = WGPU::Instance.new
        adpt = inst.request_adapter
        adpt.release
        expect(adpt.handle).to be_null
        inst.release
      end
    end
  end

  describe WGPU::Device do
    describe "#release" do
      it "sets handle to null after release" do
        inst = WGPU::Instance.new
        adpt = inst.request_adapter
        dev = adpt.request_device
        dev.release
        expect(dev.handle).to be_null
        adpt.release
        inst.release
      end
    end
  end
end
