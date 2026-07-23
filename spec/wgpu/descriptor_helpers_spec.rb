# frozen_string_literal: true

RSpec.describe WGPU::DescriptorHelpers, :skip_gpu_check do
  it "sets a label and keeps its pointer alive" do
    descriptor = WGPU::Native::BufferDescriptor.new
    keepalive = []

    described_class.set_label(descriptor, "upload", keepalive:)

    expect(descriptor[:label][:data].read_string(descriptor[:label][:length])).to eq("upload")
    expect(keepalive.length).to eq(1)
  end

  it "warns about unknown descriptor keys" do
    expect do
      described_class.validate_keys!({ width: 1, typo: 2 }, allowed: [:width], context: "texture size")
    end.to output(/Unknown texture size keys: :typo/).to_stderr
  end

  it "raises for missing required descriptor keys" do
    expect do
      described_class.validate_keys!({}, allowed: [:width], required: [:width], context: "texture size")
    end.to raise_error(ArgumentError, /missing required keys: :width/)
  end

  it "builds Buffer, Texture, and Sampler descriptors without a GPU" do
    buffer, buffer_keepalive = WGPU::Buffer.allocate.send(
      :build_descriptor,
      label: "buffer",
      size: 64,
      usage: WGPU::Native::BufferUsage[:storage],
      mapped_at_creation: true
    )
    texture, texture_keepalive = WGPU::Texture.allocate.send(
      :build_descriptor,
      label: "texture",
      size: { width: 4, height: 2 },
      format: :rgba8_unorm,
      usage: [:texture_binding, :copy_dst],
      dimension: :d2,
      mip_level_count: 1,
      sample_count: 1,
      view_formats: []
    )
    sampler, sampler_keepalive = WGPU::Sampler.allocate.send(
      :build_descriptor,
      label: "sampler",
      address_mode_u: :clamp_to_edge,
      address_mode_v: :repeat,
      address_mode_w: :mirror_repeat,
      mag_filter: :linear,
      min_filter: :nearest,
      mipmap_filter: :linear,
      lod_min_clamp: 0.0,
      lod_max_clamp: 32.0,
      compare: nil,
      max_anisotropy: 1
    )

    expect(buffer[:size]).to eq(64)
    expect(buffer[:mapped_at_creation]).to eq(1)
    expect(buffer_keepalive).not_to be_empty
    expect(texture[:size][:width]).to eq(4)
    expect(texture[:format]).to eq(:rgba8_unorm)
    expect(texture_keepalive).not_to be_empty
    expect(sampler[:address_mode_v]).to eq(:repeat)
    expect(sampler[:mag_filter]).to eq(:linear)
    expect(sampler_keepalive).not_to be_empty
  end

  it "builds RenderPipeline defaults and nested state without a GPU" do
    shader = Struct.new(:handle).new(FFI::Pointer.new(1))
    descriptor, keepalive = WGPU::RenderPipeline.allocate.send(
      :build_descriptor,
      label: "pipeline",
      layout: :auto,
      vertex: {
        module: shader,
        buffers: [{
          array_stride: 8,
          attributes: [{ format: :float32x2, offset: 0, shader_location: 0 }]
        }]
      },
      primitive: {},
      depth_stencil: nil,
      multisample: {},
      fragment: {
        module: shader,
        targets: [{ format: :rgba8_unorm, write_mask: %i[red green blue alpha] }]
      }
    )

    expect(descriptor[:layout]).to be_null
    expect(descriptor[:primitive][:topology]).to eq(:triangle_list)
    expect(descriptor[:primitive][:strip_index_format]).to eq(:undefined)
    expect(descriptor[:primitive][:front_face]).to eq(:ccw)
    expect(descriptor[:primitive][:cull_mode]).to eq(:none)
    expect(descriptor[:multisample][:count]).to eq(1)
    expect(descriptor[:multisample][:mask]).to eq(0xFFFFFFFF)
    expect(descriptor[:multisample][:alpha_to_coverage_enabled]).to eq(0)
    expect(descriptor[:vertex][:buffer_count]).to eq(1)
    expect(descriptor[:fragment]).not_to be_null
    expect(keepalive).not_to be_empty
  end

  it "builds ComputePipeline descriptors with override constants without a GPU" do
    shader = Struct.new(:handle).new(FFI::Pointer.new(1))
    descriptor, keepalive = WGPU::ComputePipeline.allocate.send(
      :build_descriptor,
      label: nil,
      layout: :auto,
      compute: { module: shader, constants: { workgroup_size: 32 } }
    )

    expect(descriptor[:layout]).to be_null
    expect(descriptor[:compute][:constant_count]).to eq(1)
    expect(descriptor[:compute][:constants]).not_to be_null
    expect(keepalive.length).to be >= 2
  end

  it "rejects invalid nested pipeline enums with valid candidates" do
    shader = Struct.new(:handle).new(FFI::Pointer.new(1))

    expect do
      WGPU::RenderPipeline.allocate.send(
        :build_descriptor,
        label: nil,
        layout: :auto,
        vertex: { module: shader },
        primitive: { topology: :triangles },
        depth_stencil: nil,
        multisample: {},
        fragment: nil
      )
    end.to raise_error(ArgumentError, /Unknown primitive topology :triangles.*:triangle_list/)
  end
end
