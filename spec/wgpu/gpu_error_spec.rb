# frozen_string_literal: true

RSpec.describe WGPU::GPUError, :skip_gpu_check do
  it "converts legacy error hashes without changing pop_error_scope" do
    error = described_class.from_hash(type: :validation, message: "bad binding")

    expect(error).to eq(described_class.new(type: :validation, message: "bad binding"))
    expect(error.to_h).to eq(type: :validation, message: "bad binding")
    expect(described_class.from_hash(type: :no_error, message: nil)).to be_nil
  end

  {
    validation: WGPU::ValidationError,
    out_of_memory: WGPU::OutOfMemoryError,
    internal: WGPU::InternalError,
    device_lost: WGPU::DeviceLostError,
    unknown: WGPU::Error
  }.each do |type, error_class|
    it "maps #{type} to #{error_class}" do
      error = described_class.new(type:, message: "details")

      expect { error.raise! }.to raise_error(error_class, /#{type}.*details/)
    end
  end

  it "registers mutable device handlers without a native device" do
    device = WGPU::Device.allocate
    state = { mutex: Mutex.new, uncaptured_error: nil, device_lost: nil }
    device.instance_variable_set(:@device_callback_state, state)

    uncaptured = proc {}
    lost = proc {}
    expect(device.on_uncaptured_error(&uncaptured)).to be(device)
    expect(device.on_device_lost(&lost)).to be(device)

    expect(state[:uncaptured_error]).to be(uncaptured)
    expect(state[:device_lost]).to be(lost)
  end

  it "retains a typed surface acquisition status" do
    error = WGPU::SurfaceAcquisitionError.new(:outdated)

    expect(error.status).to eq(:outdated)
    expect(error.message).to include("outdated")
  end
end
