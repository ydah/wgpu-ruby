# frozen_string_literal: true

RSpec.describe WGPU::GPUError, :skip_gpu_check do
  def callback_message(text)
    pointer = FFI::MemoryPointer.from_string(text)
    view = WGPU::Native::StringView.new
    view[:data] = pointer
    view[:length] = text.bytesize
    [view, pointer]
  end

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

  it "warns for an uncaptured error when no handler is registered" do
    state = { mutex: Mutex.new, uncaptured_error: nil }
    callback = WGPU::Device.send(:build_uncaptured_error_callback, state)
    message, _message_pointer = callback_message("bad binding")

    expect do
      callback.call(nil, WGPU::Native::ErrorType[:validation], message, nil, nil)
    end.to output(/Uncaptured GPU error \(validation\): bad binding/).to_stderr
  end

  it "protects the native callback boundary from handler exceptions" do
    state = {
      mutex: Mutex.new,
      uncaptured_error: proc { raise "handler boom" }
    }
    callback = WGPU::Device.send(:build_uncaptured_error_callback, state)
    message, _message_pointer = callback_message("validation failure")

    expect do
      expect do
        callback.call(nil, WGPU::Native::ErrorType[:validation], message, nil, nil)
      end.not_to raise_error
    end.to output(/WGPU uncaptured_error handler failed: RuntimeError: handler boom/).to_stderr
  end

  it "dispatches device-lost reason and message from the native callback" do
    received = []
    state = {
      mutex: Mutex.new,
      device_lost: proc { |reason, message| received << [reason, message] }
    }
    callback = WGPU::Device.send(:build_device_lost_callback, state)
    message, _message_pointer = callback_message("adapter removed")

    callback.call(
      nil,
      WGPU::Native::DeviceLostReason[:instance_dropped],
      message,
      nil,
      nil
    )

    expect(received).to eq([[:instance_dropped, "adapter removed"]])
  end

  it "keeps native device callbacks alive through child and callback completion" do
    handle = FFI::Pointer.new(1)
    buffer_handle = FFI::Pointer.new(2)
    state = {
      mutex: Mutex.new,
      uncaptured_error: nil,
      device_lost: nil
    }
    device = WGPU::Device.allocate
    device.instance_variable_set(:@handle, handle)
    device.instance_variable_set(:@queue, nil)
    device.instance_variable_set(:@device_callback_state, state)

    lost_callback = WGPU::Device.send(:build_device_lost_callback, state)
    error_callback = WGPU::Device.send(:build_uncaptured_error_callback, state)
    tokens = [
      WGPU::CallbackKeepalive.retain(device, lost_callback),
      WGPU::CallbackKeepalive.retain(device, error_callback)
    ]
    WGPU::Device.send(
      :configure_device_callback_keepalive,
      state,
      owner: device,
      tokens: tokens
    )
    device.instance_variable_set(:@device_callback_tokens, tokens)
    lifetime_class = WGPU.const_get(:DeviceCallbackLifetime, false)
    lifetime = lifetime_class.new do
      WGPU::Device.send(:release_device_callback_keepalive, state)
    end
    lifetime.retain
    device.instance_variable_set(:@device_callback_lifetime, lifetime)
    device.instance_variable_set(:@device_callback_lifetime_retained, true)

    buffer = WGPU::Buffer.allocate
    buffer.instance_variable_set(:@handle, buffer_handle)
    buffer.send(:attach_device_callback_lifetime, device)
    callback_lifetime_release = buffer.send(:device_callback_lifetime_lease)

    expect(WGPU::Native).to receive(:wgpuDeviceRelease).with(handle)
    device.release
    expect(WGPU::CallbackKeepalive.count(device)).to eq(2)

    expect(WGPU::Native).to receive(:wgpuBufferRelease).with(buffer_handle)
    buffer.release
    expect(WGPU::CallbackKeepalive.count(device)).to eq(2)

    callback_lifetime_release.call
    callback_lifetime_release.call
    expect(WGPU::CallbackKeepalive.count(device)).to eq(0)
  end

  it "keeps a native callback alive while its handler releases the device" do
    handle = FFI::Pointer.new(1)
    state = {
      mutex: Mutex.new,
      uncaptured_error: nil,
      device_lost: nil
    }
    device = WGPU::Device.allocate
    device.instance_variable_set(:@handle, handle)
    device.instance_variable_set(:@queue, nil)
    device.instance_variable_set(:@device_callback_state, state)

    lost_callback = WGPU::Device.send(:build_device_lost_callback, state)
    error_callback = WGPU::Device.send(:build_uncaptured_error_callback, state)
    tokens = [
      WGPU::CallbackKeepalive.retain(device, lost_callback),
      WGPU::CallbackKeepalive.retain(device, error_callback)
    ]
    WGPU::Device.send(
      :configure_device_callback_keepalive,
      state,
      owner: device,
      tokens: tokens
    )

    lifetime_class = WGPU.const_get(:DeviceCallbackLifetime, false)
    lifetime = lifetime_class.new do
      WGPU::Device.send(:release_device_callback_keepalive, state)
    end
    lifetime.retain
    state[:mutex].synchronize { state[:callback_lifetime] = lifetime }
    device.instance_variable_set(:@device_callback_lifetime, lifetime)
    device.instance_variable_set(:@device_callback_lifetime_retained, true)
    device.instance_variable_set(:@device_callback_tokens, tokens)

    state[:device_lost] = proc do
      device.release
      GC.start
      expect(WGPU::CallbackKeepalive.count(device)).to eq(2)
    end
    expect(WGPU::Native).to receive(:wgpuDeviceRelease).with(handle)

    lost_callback.call(
      handle,
      WGPU::Native::DeviceLostReason[:destroyed],
      callback_message("").first,
      nil,
      nil
    )
    expect(WGPU::CallbackKeepalive.count(device)).to eq(0)
  end

  it "retains a typed surface acquisition status" do
    error = WGPU::SurfaceAcquisitionError.new(:outdated)

    expect(error.status).to eq(:outdated)
    expect(error.message).to include("outdated")
  end
end
