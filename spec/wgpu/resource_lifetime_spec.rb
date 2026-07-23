# frozen_string_literal: true

RSpec.describe "resource lifetime", :skip_gpu_check do
  let(:handle) { FFI::Pointer.new(1) }

  it "makes release idempotent by nulling a native handle" do
    buffer = WGPU::Buffer.allocate
    buffer.instance_variable_set(:@handle, handle)
    allow(WGPU::Native).to receive(:wgpuBufferRelease)

    2.times { buffer.release }

    expect(WGPU::Native).to have_received(:wgpuBufferRelease).once
    expect(buffer.handle).to be_null
  end

  it "releases a device queue before the device handle" do
    queue = instance_double(WGPU::Queue, release: nil)
    device = WGPU::Device.allocate
    device.instance_variable_set(:@queue, queue)
    device.instance_variable_set(:@handle, handle)
    allow(WGPU::Native).to receive(:wgpuDeviceRelease)

    device.release

    expect(queue).to have_received(:release).once
    expect(WGPU::Native).to have_received(:wgpuDeviceRelease).with(handle).once
    expect(device.handle).to be_null
  end

  it "keeps the wrapper reference after destroy until release" do
    texture = WGPU::Texture.allocate
    texture.instance_variable_set(:@handle, handle)
    allow(WGPU::Native).to receive(:wgpuTextureDestroy)

    texture.destroy

    expect(WGPU::Native).to have_received(:wgpuTextureDestroy).with(handle).once
    expect(texture.handle).to eq(handle)
  end
end
