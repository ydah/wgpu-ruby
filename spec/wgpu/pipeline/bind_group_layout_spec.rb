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
end
