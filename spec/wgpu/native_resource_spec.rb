# frozen_string_literal: true

RSpec.describe WGPU::NativeResource, :skip_gpu_check do
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
    resource_classes = [
      WGPU::Instance, WGPU::Adapter, WGPU::Device, WGPU::Queue,
      WGPU::Surface, WGPU::CanvasContext, WGPU::Buffer, WGPU::Texture,
      WGPU::TextureView, WGPU::Sampler, WGPU::QuerySet, WGPU::ShaderModule,
      WGPU::BindGroupLayout, WGPU::BindGroup, WGPU::PipelineLayout,
      WGPU::ComputePipeline, WGPU::RenderPipeline, WGPU::CommandEncoder,
      WGPU::CommandBuffer, WGPU::ComputePass, WGPU::RenderPass,
      WGPU::RenderBundleEncoder, WGPU::RenderBundle
    ]

    expect(resource_classes).to all(be < described_class)
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
end
