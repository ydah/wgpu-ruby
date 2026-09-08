# frozen_string_literal: true

RSpec.describe "request validation and cleanup", :skip_gpu_check do
  let(:instance) do
    WGPU::Instance.allocate.tap { |value| value.instance_variable_set(:@handle, FFI::Pointer.new(1)) }
  end
  let(:adapter) { WGPU::Adapter.from_handle(FFI::Pointer.new(2), instance: instance) }

  [-1, Float::NAN, Float::INFINITY, -Float::INFINITY, "invalid", false].each do |timeout|
    it "rejects #{timeout.inspect} before requesting an adapter or device" do
      expect(WGPU::Native).not_to receive(:wgpuInstanceRequestAdapter)
      expect(WGPU::Native).not_to receive(:wgpuAdapterRequestDevice)
      expect { WGPU::Adapter.request(instance, timeout: timeout) }.to raise_error(ArgumentError)
      expect { adapter.request_device(timeout: timeout) }.to raise_error(ArgumentError)
      expect(WGPU::CallbackKeepalive.count(instance)).to eq(0)
      expect(WGPU::CallbackKeepalive.count(adapter)).to eq(0)
    end
  end

  [:adapter, :device].each do |kind|
    [false, true].each do |late|
      it "releases a #{late ? 'late' : 'completed'} #{kind} after a non-timeout wait failure" do
        callbacks = []
        allow(WGPU::CallbackKeepalive).to receive(:retain).and_wrap_original do |method, owner, callback|
          callbacks << callback
          method.call(owner, callback)
        end
        handle = FFI::Pointer.new(3)
        callback_args = [1, handle, WGPU::Native::StringView.new, nil, nil]
        native_request = kind == :adapter ? :wgpuInstanceRequestAdapter : :wgpuAdapterRequestDevice
        allow(WGPU::Native).to receive(native_request) do
          callbacks.last.call(*callback_args) unless late
          nil
        end
        allow(WGPU::AsyncWaiter).to receive(:wait).and_raise(WGPU::Error, "wait failed")
        expect(WGPU::Native).to receive(kind == :adapter ? :wgpuAdapterRelease : :wgpuDeviceRelease).with(handle).once
        expect do
          kind == :adapter ? WGPU::Adapter.request(instance) : adapter.request_device
        end.to raise_error(WGPU::Error, "wait failed")
        callbacks.last.call(*callback_args) if late
        expect(WGPU::CallbackKeepalive.count(instance)).to eq(0)
        expect(WGPU::CallbackKeepalive.count(adapter)).to eq(0)
      end
    end
  end

  [:Adapter, :Device].each do |kind|
    [false, true].each do |fail_conversion|
      it "frees #{kind} feature storage#{' even when conversion raises' if fail_conversion}" do
        owner = WGPU.const_get(kind).allocate
        owner.instance_variable_set(:@handle, FFI::Pointer.new(1))
        features = FFI::MemoryPointer.new(:uint32)
        features.write_uint32(WGPU::Native::FeatureName[:timestamp_query])
        allow(WGPU::Native).to receive(:"wgpu#{kind}GetFeatures") do |_handle, supported|
          supported[:feature_count] = 1
          supported[:features] = features
        end
        expect(WGPU::Native).to receive(:wgpuSupportedFeaturesFreeMembers) do |supported|
          expect(supported[:features]).to eq(features)
        end
        if fail_conversion
          allow(WGPU::Native::FeatureName).to receive(:[]).and_raise("conversion failed")
          expect { owner.features }.to raise_error("conversion failed")
        else
          expect(owner.features).to eq([:timestamp_query])
        end
      end
    end
  end
end
