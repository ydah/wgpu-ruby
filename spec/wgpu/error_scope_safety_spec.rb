# frozen_string_literal: true

RSpec.describe "error scope ownership", :skip_gpu_check do
  let(:device) do
    WGPU::Device.allocate.tap { |device| device.instance_variable_set(:@handle, FFI::Pointer.new(1)) }
  end

  def scope_callback(info)
    device.instance_variable_get(:@wgpu_callback_keepalive).values.find do |callback|
      callback.address == info[:callback].address
    end
  end

  before do
    @scopes = []
    allow(WGPU::Native).to receive(:wgpuDevicePushErrorScope) do |_handle, filter|
      @scopes << filter
    end
    allow(WGPU::Native).to receive(:wgpuDevicePopErrorScope) do |_handle, info|
      @scopes.pop
      scope_callback(info).call(WGPU::Native::PopErrorScopeStatus[:success],
        WGPU::Native::ErrorType[:no_error], WGPU::Native::StringView.new, nil, nil)
      nil
    end
  end

  it "rejects every empty pop before FFI" do
    expect(WGPU::Native).not_to receive(:wgpuDevicePopErrorScope)
    [:pop_error_scope, :pop_error_scope_typed, :pop_error_scope_async].each do |method|
      expect { device.public_send(method) }.to raise_error(WGPU::DeviceError, /No error scope/)
    end
  end

  it "cleans up nested scopes when the block raises and rejects missing blocks" do
    failure = RuntimeError.new("application failure")
    expect do
      device.with_error_scope { device.with_error_scope { raise failure } }
    end.to(raise_error { |error| expect(error).to equal(failure) })
    expect(@scopes).to be_empty
    expect { device.with_error_scope }.to raise_error(ArgumentError, /block/)
    expect(@scopes).to be_empty
    expect(device.with_error_scope { 42 }).to eq(42)
  end

  it "preserves the block exception even if popping fails" do
    allow(WGPU::Native).to receive(:wgpuDevicePopErrorScope).and_raise("pop failed")
    expect { device.with_error_scope { raise "application failure" } }.to raise_error("application failure")
    expect(device.instance_variable_get(:@error_scope_monitor).mon_owned?).to be(false)
    expect(WGPU::CallbackKeepalive.count(device)).to eq(0)
  end

  it "initiates an async pop before a subsequent push and only waits in the task" do
    callbacks = []
    allow(WGPU::Native).to receive(:wgpuDevicePopErrorScope) do |_handle, info|
      @scopes.pop
      callbacks << scope_callback(info)
      nil
    end
    allow(WGPU::Native).to receive(:device_poll_available?).and_return(false)
    device.push_error_scope(:validation)
    task = device.pop_error_scope_async
    expect(@scopes).to be_empty
    device.push_error_scope(:out_of_memory)
    callbacks.first.call(WGPU::Native::PopErrorScopeStatus[:success],
      WGPU::Native::ErrorType[:validation], WGPU::Native::StringView.new, nil, nil)
    expect(task.value(timeout: 2)[:type]).to eq(:validation)
    expect(@scopes).to eq([WGPU::Native::ErrorFilter[:out_of_memory]])
    second = device.pop_error_scope_async
    callbacks.last.call(WGPU::Native::PopErrorScopeStatus[:success],
      WGPU::Native::ErrorType[:no_error], WGPU::Native::StringView.new, nil, nil)
    expect(second.value(timeout: 2)[:type]).to eq(:no_error)
    expect(WGPU::CallbackKeepalive.count(device)).to eq(0)
  ensure
    callbacks&.each do |callback|
      callback.call(WGPU::Native::PopErrorScopeStatus[:success],
        WGPU::Native::ErrorType[:no_error], WGPU::Native::StringView.new, nil, nil)
    end
    task&.wait(timeout: 2)
    second&.wait(timeout: 2)
  end

  it "serializes operations across threads while allowing nested scopes" do
    entered = Queue.new
    proceed = Queue.new
    sequence = []
    first = Thread.new do
      device.with_error_scope do
        sequence << :first
        entered << true
        proceed.pop
        device.with_error_scope { sequence << :nested }
      end
    end
    entered.pop
    second_started = Queue.new
    second = Thread.new do
      second_started << true
      device.with_error_scope { sequence << :second }
    end
    second_started.pop
    expect(second.join(0.05)).to be_nil
    expect(sequence).to eq([:first])
    proceed << true
    expect(first.join(2)).not_to be_nil
    expect(second.join(2)).not_to be_nil
    expect(sequence).to eq([:first, :nested, :second])
    expect(@scopes).to be_empty
  ensure
    first&.kill if first&.alive?
    second&.kill if second&.alive?
  end

  it "rejects a pop from a different thread without consuming the owner's scope" do
    device.push_error_scope
    result = Thread.new do
      device.pop_error_scope
    rescue WGPU::DeviceError => error
      error
    end.value
    expect(result).to be_a(WGPU::DeviceError)
    expect(@scopes.size).to eq(1)
    device.pop_error_scope
  end

  {
    Buffer: { size: 16, usage: :storage },
    Texture: { size: { width: 1 }, format: :rgba8_unorm, usage: :texture_binding },
    Sampler: {},
    BindGroupLayout: { entries: [] },
    PipelineLayout: { bind_group_layouts: [] },
    ShaderModule: { code: "@compute @workgroup_size(1) fn main() {}" },
    BindGroup: {},
    ComputePipeline: {},
    RenderPipeline: {}
  }.each do |name, arguments|
    it "releases the non-null #{name} error handle during failed initialization" do
      handle = FFI::Pointer.new(2)
      shader = WGPU::ShaderModule.allocate
      shader.instance_variable_set(:@handle, FFI::Pointer.new(3))
      layout = WGPU::BindGroupLayout.from_handle(FFI::Pointer.new(4))
      arguments = case name
                  when :BindGroup then { layout: layout, entries: [] }
                  when :ComputePipeline then { layout: :auto, compute: { module: shader } }
                  when :RenderPipeline then { layout: :auto, vertex: { module: shader } }
                  else arguments
                  end
      allow(WGPU::Native).to receive(:"wgpuDeviceCreate#{name}").and_return(handle)
      allow(WGPU::Native).to receive(:wgpuDevicePopErrorScope) do |_handle, info|
        @scopes.pop
        scope_callback(info).call(WGPU::Native::PopErrorScopeStatus[:success],
          WGPU::Native::ErrorType[:validation], WGPU::Native::StringView.new, nil, nil)
        nil
      end
      expect(WGPU::Native).to receive(:"wgpu#{name}Release").with(handle).once
      expect { WGPU.const_get(name).new(device, **arguments) }.to raise_error(WGPU::Error)
      expect(@scopes).to be_empty
    end
  end

  it "pops the scope when native creation itself raises" do
    allow(WGPU::Native).to receive(:wgpuDeviceCreateBuffer).and_raise("creation failed")
    expect { device.create_buffer(size: 16, usage: :storage) }.to raise_error("creation failed")
    expect(@scopes).to be_empty
  end
end
