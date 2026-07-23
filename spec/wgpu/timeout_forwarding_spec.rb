# frozen_string_literal: true

RSpec.describe "synchronous timeout forwarding", :skip_gpu_check do
  let(:pointer) { FFI::Pointer.new(1) }
  let(:timeout) { 1.25 }

  before do
    allow(WGPU::AsyncWaiter).to receive(:wait).and_raise(
      WGPU::TimeoutError,
      "timeout sentinel"
    )
  end

  def expect_forwarded_timeout(timeout)
    expect { yield }.to raise_error(WGPU::TimeoutError, "timeout sentinel")
    expect(WGPU::AsyncWaiter).to have_received(:wait).with(
      hash_including(timeout: timeout)
    )
  end

  it "forwards Buffer#map_sync timeout" do
    device = Struct.new(:adapter).new(nil)
    buffer = WGPU::Buffer.allocate
    buffer.instance_variable_set(:@handle, pointer)
    buffer.instance_variable_set(:@size, 4)
    buffer.instance_variable_set(:@device, device)
    allow(WGPU::Native).to receive(:wgpuBufferMapAsync).and_return(Object.new)

    expect_forwarded_timeout(timeout) { buffer.map_sync(:read, timeout: timeout) }
  end

  it "forwards Device.request timeout" do
    adapter = WGPU::Adapter.from_handle(pointer)
    allow(WGPU::Native).to receive(:wgpuAdapterRequestDevice).and_return(Object.new)

    expect_forwarded_timeout(timeout) do
      WGPU::Device.request(adapter, timeout: timeout)
    end
  end

  it "forwards Device#pop_error_scope timeout" do
    device = WGPU::Device.allocate
    device.instance_variable_set(:@handle, pointer)
    device.instance_variable_set(:@adapter, nil)
    allow(WGPU::Native).to receive(:wgpuDevicePopErrorScope).and_return(Object.new)

    expect_forwarded_timeout(timeout) { device.pop_error_scope(timeout: timeout) }
  end

  it "forwards Queue#on_submitted_work_done timeout" do
    device = Struct.new(:adapter, :handle).new(nil, pointer)
    queue = WGPU::Queue.new(pointer, device: device)
    allow(WGPU::Native).to receive(:wgpuQueueOnSubmittedWorkDone).and_return(Object.new)

    expect_forwarded_timeout(timeout) do
      queue.on_submitted_work_done(timeout: timeout)
    end
  end
end
