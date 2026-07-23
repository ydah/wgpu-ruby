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

    it "keeps callback fields at ABI-stable offsets" do
      pointer_size = FFI::Pointer.size
      callback_info = WGPU::Native::RequestAdapterCallbackInfo

      expect(callback_info.offset_of(:next_in_chain)).to eq(0)
      expect(callback_info.offset_of(:mode)).to eq(pointer_size)
      expect(callback_info.offset_of(:callback)).to eq(pointer_size * 2)
      expect(callback_info.offset_of(:userdata1)).to eq(pointer_size * 3)
      expect(callback_info.offset_of(:userdata2)).to eq(pointer_size * 4)
    end

    it "keeps StringView fields at pointer-sized offsets" do
      expect(WGPU::Native::StringView.offset_of(:data)).to eq(0)
      expect(WGPU::Native::StringView.offset_of(:length)).to eq(FFI::Pointer.size)
    end
  end

  describe "future API types" do
    it "defines future structs" do
      expect(WGPU::Native::Future.size).to eq(8)
      expect(WGPU::Native::FutureWaitInfo.members).to eq([:future, :completed])
      expect(WGPU::Native::FutureWaitInfo.size).to eq(16)
    end
  end

  describe "texture view descriptor layout" do
    it "includes the v27 usage field at the ABI-stable offset" do
      descriptor = WGPU::Native::TextureViewDescriptor

      expect(descriptor.members.last).to eq(:usage)
      expect(descriptor.offset_of(:usage)).to eq(56)
      expect(descriptor.size).to eq(64)
    end
  end

  describe "runtime capability checks" do
    it "reports availability from bound functions" do
      expect(WGPU::Native.future_api?).to eq(
        WGPU::Native.optional_function_available?(:wgpuInstanceWaitAny)
      )
      expect(WGPU::Native.device_poll_available?).to eq(
        WGPU::Native.optional_function_available?(:wgpuDevicePoll)
      )
    end

    it "loads missing optional symbols and raises only when called" do
      library = Module.new do
        extend FFI::Library
        extend WGPU::Native::OptionalFunctions
        ffi_lib FFI::Library::LIBC
      end

      expect do
        library.attach_optional_function(:wgpuDefinitelyMissingForSpec, [], :void)
      end.not_to raise_error
      expect(library.optional_function_available?(:wgpuDefinitelyMissingForSpec)).to be(false)
      expect { library.wgpuDefinitelyMissingForSpec }.to raise_error(
        WGPU::Error,
        /Optional wgpu-native function wgpuDefinitelyMissingForSpec is unavailable/
      )
    end
  end

  describe WGPU::Native::AbiVerifier do
    it "matches every Ruby FFI enum with the checksum-pinned webgpu.h" do
      expect(described_class.new.verify!).to be(true)
    end
  end
end
