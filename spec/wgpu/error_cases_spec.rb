# frozen_string_literal: true

RSpec.describe "Error handling" do
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
