# frozen_string_literal: true

RSpec.describe WGPU::NativeResource, :skip_gpu_check do
  native_wrapper_classes = [
    WGPU::Instance, WGPU::Adapter, WGPU::Device, WGPU::Queue,
    WGPU::Surface, WGPU::CanvasContext, WGPU::Buffer, WGPU::Texture,
    WGPU::TextureView, WGPU::Sampler, WGPU::QuerySet, WGPU::ShaderModule,
    WGPU::BindGroupLayout, WGPU::BindGroup, WGPU::PipelineLayout,
    WGPU::ComputePipeline, WGPU::RenderPipeline, WGPU::CommandEncoder,
    WGPU::CommandBuffer, WGPU::ComputePass, WGPU::RenderPass,
    WGPU::RenderBundleEncoder, WGPU::RenderBundle
  ].freeze

  let(:resource_class) do
    Class.new do
      attr_reader :handle

      def initialize(label: nil)
        @handle = FFI::Pointer.new(1)
        @label = label
      end

      def ping
        :pong
      end

      def release
        @handle = FFI::Pointer::NULL
      end

      include WGPU::NativeResource
    end
  end

  it "is included by every native wrapper" do
    expect(native_wrapper_classes.size).to eq(23)
    expect(native_wrapper_classes).to all(be < described_class)
  end

  it "guards every public wrapper method and rejects calls after release" do
    exemptions = described_class::GUARDED_METHOD_EXEMPTIONS

    native_wrapper_classes.each do |wrapper_class|
      methods_to_guard = wrapper_class.public_instance_methods(false) - exemptions
      lifecycle_index = wrapper_class.ancestors.index(WGPU::NativeResource::Lifecycle)
      guard_module = wrapper_class.ancestors.fetch(lifecycle_index + 1)

      unless methods_to_guard.empty?
        expect(guard_module.public_instance_methods(false)).to include(*methods_to_guard)
      end

      resource = wrapper_class.allocate
      resource.instance_variable_set(:@released, true)
      resource.instance_variable_set(:@label, "released acceptance")

      expect { resource.use { :unused } }.to raise_error(WGPU::ResourceError, /released/)
      methods_to_guard.each do |method_name|
        expect { resource.public_send(method_name) }.to raise_error(
          WGPU::ResourceError,
          /released acceptance.*released/
        ), "#{wrapper_class}##{method_name} bypassed the release guard"
      end
    end
  end

  it "reports released state and guards public methods" do
    resource = resource_class.new(label: "temporary")
    expect(resource.released?).to be(false)
    expect(resource.ping).to eq(:pong)

    resource.release

    expect(resource.released?).to be(true)
    expect { resource.ping }.to raise_error(WGPU::ResourceError, /temporary.*released/)
  end

  it "keeps release idempotent" do
    resource = resource_class.new
    expect { 2.times { resource.release } }.not_to raise_error
  end

  it "shows the label and released state in inspect" do
    resource = resource_class.new(label: "upload")
    expect(resource.inspect).to include("label=\"upload\"", "released=false")
  end

  it "returns the block result and releases after use" do
    resource = resource_class.new

    result = resource.use { |yielded| yielded.ping }

    expect(result).to eq(:pong)
    expect(resource).to be_released
  end

  it "releases after an exception in use" do
    resource = resource_class.new

    expect { resource.use { raise "boom" } }.to raise_error("boom")
    expect(resource).to be_released
  end
end

RSpec.describe WGPU::CallbackKeepalive, :skip_gpu_check do
  it "retains callbacks by owner until their token is released" do
    owner = Object.new
    callback = proc {}

    token = described_class.retain(owner, callback)

    expect(described_class.count(owner)).to eq(1)
    expect(owner.instance_variable_get(:@wgpu_callback_keepalive).value?(callback)).to be(true)

    described_class.release(owner, token)
    expect(described_class.count(owner)).to eq(0)
  end

  it "makes release idempotent" do
    owner = Object.new
    token = described_class.retain(owner, proc {})

    2.times { described_class.release(owner, token) }

    expect(described_class.count(owner)).to eq(0)
  end
end
