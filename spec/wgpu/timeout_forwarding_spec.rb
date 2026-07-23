# frozen_string_literal: true

RSpec.describe "synchronous timeout forwarding", :skip_gpu_check do
  let(:pointer) { FFI::Pointer.new(1) }
  let(:timeout) { 1.25 }

  before do
    @retained_callbacks = []
    allow(WGPU::CallbackKeepalive).to receive(:retain).and_wrap_original do |method, owner, callback|
      @retained_callbacks << callback
      method.call(owner, callback)
    end
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

  def empty_message
    message = WGPU::Native::StringView.new
    message[:data] = nil
    message[:length] = 0
    message
  end

  it "forwards Buffer#map_sync timeout" do
    device = Struct.new(:adapter).new(nil)
    buffer = WGPU::Buffer.allocate
    buffer.instance_variable_set(:@handle, pointer)
    buffer.instance_variable_set(:@size, 4)
    buffer.instance_variable_set(:@device, device)
    allow(WGPU::Native).to receive(:wgpuBufferMapAsync).and_return(Object.new)

    expect_forwarded_timeout(timeout) { buffer.map_sync(:read, timeout: timeout) }
    expect(WGPU::CallbackKeepalive.count(buffer)).to eq(1)

    @retained_callbacks.last.call(
      WGPU::Native::MapAsyncStatus[:success],
      empty_message,
      nil,
      nil
    )
    expect(WGPU::CallbackKeepalive.count(buffer)).to eq(0)
  end

  it "keeps an adapter callback alive and releases a late successful handle" do
    instance = WGPU::Instance.allocate
    instance.instance_variable_set(:@handle, pointer)
    late_adapter = FFI::Pointer.new(2)
    allow(WGPU::Native).to receive(:wgpuInstanceRequestAdapter).and_return(Object.new)
    expect(WGPU::Native).to receive(:wgpuAdapterRelease).with(late_adapter)

    expect_forwarded_timeout(timeout) do
      WGPU::Adapter.request(instance, timeout: timeout)
    end
    expect(WGPU::CallbackKeepalive.count(instance)).to eq(1)

    @retained_callbacks.last.call(
      WGPU::Native::RequestAdapterStatus[:success],
      late_adapter,
      empty_message,
      nil,
      nil
    )
    expect(WGPU::CallbackKeepalive.count(instance)).to eq(0)
  end

  it "forwards Device.request timeout" do
    adapter = WGPU::Adapter.from_handle(pointer)
    late_device = FFI::Pointer.new(2)
    allow(WGPU::Native).to receive(:wgpuAdapterRequestDevice).and_return(Object.new)
    expect(WGPU::Native).to receive(:wgpuDeviceRelease).with(late_device)

    expect_forwarded_timeout(timeout) do
      WGPU::Device.request(adapter, timeout: timeout)
    end
    expect(WGPU::CallbackKeepalive.count(adapter)).to eq(3)

    @retained_callbacks.last.call(
      WGPU::Native::RequestDeviceStatus[:success],
      late_device,
      empty_message,
      nil,
      nil
    )
    expect(WGPU::CallbackKeepalive.count(adapter)).to eq(0)
  end

  it "forwards Device#pop_error_scope timeout" do
    device = WGPU::Device.allocate
    device.instance_variable_set(:@handle, pointer)
    device.instance_variable_set(:@adapter, nil)
    allow(WGPU::Native).to receive(:wgpuDevicePopErrorScope).and_return(Object.new)

    expect_forwarded_timeout(timeout) { device.pop_error_scope(timeout: timeout) }
    expect(WGPU::CallbackKeepalive.count(device)).to eq(1)

    @retained_callbacks.last.call(
      WGPU::Native::PopErrorScopeStatus[:success],
      WGPU::Native::ErrorType[:no_error],
      empty_message,
      nil,
      nil
    )
    expect(WGPU::CallbackKeepalive.count(device)).to eq(0)
  end

  it "forwards Queue#on_submitted_work_done timeout" do
    device = Struct.new(:adapter, :handle).new(nil, pointer)
    queue = WGPU::Queue.new(pointer, device: device)
    allow(WGPU::Native).to receive(:wgpuQueueOnSubmittedWorkDone).and_return(Object.new)

    expect_forwarded_timeout(timeout) do
      queue.on_submitted_work_done(timeout: timeout)
    end
    expect(WGPU::CallbackKeepalive.count(queue)).to eq(1)

    @retained_callbacks.last.call(
      WGPU::Native::QueueWorkDoneStatus[:success],
      nil,
      nil
    )
    expect(WGPU::CallbackKeepalive.count(queue)).to eq(0)
  end
end
