# frozen_string_literal: true

RSpec.describe WGPU::BindGroupLayout, :skip_gpu_check do
  subject(:layout) { described_class.allocate }

  it "builds all four WebGPU resource variants without a GPU" do
    descriptor, keepalive = layout.send(
      :build_descriptor,
      label: "layout",
      entries: [
        { binding: 0, visibility: :compute, buffer: { type: :storage } },
        { binding: 1, visibility: :fragment, sampler: { type: :filtering } },
        {
          binding: 2,
          visibility: %i[fragment vertex],
          texture: { sample_type: :float, view_dimension: :d2 }
        },
        {
          binding: 3,
          visibility: :compute,
          storage_texture: { access: :write_only, format: :rgba8_unorm }
        }
      ]
    )

    entries = descriptor[:entries]
    buffer_entry = WGPU::Native::BindGroupLayoutEntry.new(entries)
    storage_entry = WGPU::Native::BindGroupLayoutEntry.new(
      entries + (3 * WGPU::Native::BindGroupLayoutEntry.size)
    )

    expect(descriptor[:entry_count]).to eq(4)
    expect(buffer_entry[:buffer][:type]).to eq(:storage)
    expect(storage_entry[:storage_texture][:format]).to eq(:rgba8_unorm)
    expect(keepalive).not_to be_empty
  end

  it "rejects missing or conflicting resource variants" do
    expect do
      layout.send(:create_entry, binding: 0, visibility: :compute)
    end.to raise_error(ArgumentError, /exactly one resource variant/)

    expect do
      layout.send(
        :create_entry,
        binding: 0,
        visibility: :compute,
        buffer: {},
        sampler: {}
      )
    end.to raise_error(ArgumentError, /exactly one resource variant/)
  end

  it "requires a storage texture format" do
    expect do
      layout.send(
        :create_entry,
        binding: 0,
        visibility: :compute,
        storage_texture: { access: :write_only }
      )
    end.to raise_error(ArgumentError, /missing required keys: :format/)
  end

  it "applies documented defaults to every nested resource descriptor" do
    buffer = layout.send(
      :create_entry,
      binding: 0,
      visibility: :compute,
      buffer: {}
    )
    sampler = layout.send(
      :create_entry,
      binding: 1,
      visibility: :fragment,
      sampler: {}
    )
    texture = layout.send(
      :create_entry,
      binding: 2,
      visibility: :fragment,
      texture: {}
    )
    storage_texture = layout.send(
      :create_entry,
      binding: 3,
      visibility: :compute,
      storage_texture: { format: :rgba8_unorm }
    )

    expect(buffer[:buffer][:type]).to eq(:storage)
    expect(buffer[:buffer][:has_dynamic_offset]).to eq(0)
    expect(buffer[:buffer][:min_binding_size]).to eq(0)
    expect(sampler[:sampler][:type]).to eq(:filtering)
    expect(texture[:texture][:sample_type]).to eq(:float)
    expect(texture[:texture][:view_dimension]).to eq(:d2)
    expect(texture[:texture][:multisampled]).to eq(0)
    expect(storage_texture[:storage_texture][:access]).to eq(:write_only)
    expect(storage_texture[:storage_texture][:view_dimension]).to eq(:d2)
  end

  {
    buffer: { unknown: true },
    sampler: { unknown: true },
    texture: { unknown: true },
    storage_texture: { format: :rgba8_unorm, unknown: true }
  }.each do |variant, descriptor|
    it "warns about unknown nested #{variant} keys" do
      expect do
        layout.send(
          :create_entry,
          binding: 0,
          visibility: :compute,
          variant => descriptor
        )
      end.to output(/Unknown .* binding layout keys: :unknown/).to_stderr
    end
  end
end

RSpec.describe WGPU::BindGroup, :skip_gpu_check do
  subject(:bind_group) { described_class.allocate }

  it "rejects a missing resource" do
    expect do
      bind_group.send(:create_entry, binding: 0)
    end.to raise_error(ArgumentError, /exactly one resource/)
  end

  it "rejects conflicting resources" do
    expect do
      bind_group.send(
        :create_entry,
        binding: 0,
        buffer: Object.new,
        sampler: Object.new
      )
    end.to raise_error(ArgumentError, /exactly one resource/)
  end
end
