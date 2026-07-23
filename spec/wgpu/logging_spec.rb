# frozen_string_literal: true

RSpec.describe "native logging", :skip_gpu_check do
  it "sets a validated native log level" do
    allow(WGPU::Native).to receive(:logging_available?).and_return(true)
    expect(WGPU::Native).to receive(:wgpuSetLogLevel).with(WGPU::Native::LogLevel[:debug])

    expect(WGPU.log_level = :debug).to eq(:debug)
    expect(WGPU.log_level).to eq(:debug)
  end

  it "retains and dispatches the native log callback" do
    messages = []
    allow(WGPU::Native).to receive(:logging_available?).and_return(true)
    expect(WGPU::Native).to receive(:wgpuSetLogCallback)

    WGPU.on_log { |level, message| messages << [level, message] }
    callback = WGPU.instance_variable_get(:@native_log_callback)
    message_pointer = FFI::MemoryPointer.from_string("adapter selected")
    message = WGPU::Native::StringView.new
    message[:data] = message_pointer
    message[:length] = "adapter selected".bytesize
    callback.call(WGPU::Native::LogLevel[:info], message, nil)

    expect(messages).to eq([[:info, "adapter selected"]])
    expect(callback).to equal(WGPU.instance_variable_get(:@native_log_callback))
  end
end
