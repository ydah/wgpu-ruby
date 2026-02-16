# frozen_string_literal: true

RSpec.describe WGPU::Native, :skip_gpu_check do
  describe "enum mappings" do
    it "matches v27 async status enums" do
      expect(WGPU::Native::RequestAdapterStatus[5]).to eq(:unknown)
      expect(WGPU::Native::RequestDeviceStatus[4]).to eq(:unknown)
      expect(WGPU::Native::MapAsyncStatus[5]).to eq(:unknown)
      expect(WGPU::Native::PopErrorScopeStatus[2]).to eq(:instance_dropped)
      expect(WGPU::Native::PopErrorScopeStatus[3]).to eq(:empty_stack)
    end

    it "defines callback and wait enums" do
      expect(WGPU::Native::CallbackMode[:wait_any_only]).to eq(1)
      expect(WGPU::Native::CallbackMode[:allow_process_events]).to eq(2)
      expect(WGPU::Native::CallbackMode[:allow_spontaneous]).to eq(3)

      expect(WGPU::Native::WaitStatus[:success]).to eq(1)
      expect(WGPU::Native::WaitStatus[:timed_out]).to eq(2)
      expect(WGPU::Native::WaitStatus[:unsupported_timeout]).to eq(3)
      expect(WGPU::Native::WaitStatus[:unsupported_count]).to eq(4)
      expect(WGPU::Native::WaitStatus[:unsupported_mixed_sources]).to eq(5)
    end
  end

  describe "callback info layout" do
    it "uses userdata1/2 fields with expected sizes" do
      expect(WGPU::Native::RequestAdapterCallbackInfo.members).to include(:userdata1, :userdata2)
      expect(WGPU::Native::RequestDeviceCallbackInfo.members).to include(:userdata1, :userdata2)
      expect(WGPU::Native::BufferMapCallbackInfo.members).to include(:userdata1, :userdata2)
      expect(WGPU::Native::DeviceLostCallbackInfo.members).to include(:userdata1, :userdata2)
      expect(WGPU::Native::UncapturedErrorCallbackInfo.members).to include(:userdata1, :userdata2)

      expect(WGPU::Native::RequestAdapterCallbackInfo.size).to eq(40)
      expect(WGPU::Native::RequestDeviceCallbackInfo.size).to eq(40)
      expect(WGPU::Native::BufferMapCallbackInfo.size).to eq(40)
      expect(WGPU::Native::DeviceLostCallbackInfo.size).to eq(40)
      expect(WGPU::Native::UncapturedErrorCallbackInfo.size).to eq(32)
      expect(WGPU::Native::QueueWorkDoneCallbackInfo.size).to eq(40)
      expect(WGPU::Native::CompilationInfoCallbackInfo.size).to eq(40)
    end
  end

  describe "future API types" do
    it "defines future structs" do
      expect(WGPU::Native::Future.size).to eq(8)
      expect(WGPU::Native::FutureWaitInfo.members).to eq([:future, :completed])
      expect(WGPU::Native::FutureWaitInfo.size).to eq(16)
    end
  end

  describe "runtime capability checks" do
    it "reports availability from bound functions" do
      expect(WGPU::Native.future_api?).to eq(WGPU::Native.respond_to?(:wgpuInstanceWaitAny))
      expect(WGPU::Native.device_poll_available?).to eq(WGPU::Native.respond_to?(:wgpuDevicePoll))
    end
  end
end
