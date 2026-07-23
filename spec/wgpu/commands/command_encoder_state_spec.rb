# frozen_string_literal: true

RSpec.describe WGPU::CommandEncoder, :skip_gpu_check do
  subject(:encoder) do
    described_class.allocate.tap do |value|
      value.instance_variable_set(:@handle, FFI::Pointer.new(1))
      value.instance_variable_set(:@finished, false)
      value.instance_variable_set(:@active_pass, nil)
    end
  end

  it "rejects finish while a pass is active" do
    active_pass = instance_double(WGPU::ComputePass, ended?: false)
    encoder.instance_variable_set(:@active_pass, active_pass)

    expect { encoder.finish }.to raise_error(WGPU::CommandError, /while a pass is active/)
  end

  it "ends and releases a block compute pass when the block raises" do
    pass = instance_double(WGPU::ComputePass, ended?: false)
    allow(WGPU::ComputePass).to receive(:new).and_return(pass)
    allow(pass).to receive(:end_pass)
    allow(pass).to receive(:release)

    expect do
      encoder.begin_compute_pass { raise "boom" }
    end.to raise_error(RuntimeError, "boom")

    expect(pass).to have_received(:end_pass)
    expect(pass).to have_received(:release)
  end

  it "returns the block value and clears render pass state" do
    pass = instance_double(WGPU::RenderPass, ended?: false)
    allow(WGPU::RenderPass).to receive(:new).and_return(pass)
    allow(pass).to receive(:end_pass)
    allow(pass).to receive(:release)

    result = encoder.begin_render_pass(color_attachments: []) { :rendered }

    expect(result).to eq(:rendered)
    expect(encoder.instance_variable_get(:@active_pass)).to be_nil
  end
end
