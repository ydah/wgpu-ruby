# frozen_string_literal: true

RSpec.describe WGPU::BindGroupLayout, :gpu do
  let(:instance) { WGPU::Instance.new }
  let(:adapter) { instance.request_adapter }
  let(:device) { adapter.request_device }

  after do
    device.release
    adapter.release
    instance.release
  end

  describe "#initialize" do
    it "creates a bind group layout with buffer binding" do
      layout = device.create_bind_group_layout(entries: [
        { binding: 0, visibility: :compute, buffer: { type: :storage } }
      ])
      expect(layout).to be_a(WGPU::BindGroupLayout)
      expect(layout.handle).not_to be_null
      layout.release
    end

    it "creates a bind group layout with label" do
      layout = device.create_bind_group_layout(
        label: "test layout",
        entries: [
          { binding: 0, visibility: :compute, buffer: { type: :uniform } }
        ]
      )
      expect(layout.handle).not_to be_null
      layout.release
    end

    it "creates a bind group layout with multiple entries" do
      layout = device.create_bind_group_layout(entries: [
        { binding: 0, visibility: :compute, buffer: { type: :storage } },
        { binding: 1, visibility: :compute, buffer: { type: :storage } }
      ])
      expect(layout).to be_a(WGPU::BindGroupLayout)
      layout.release
    end

    it "creates a bind group layout with sampler binding" do
      layout = device.create_bind_group_layout(entries: [
        { binding: 0, visibility: :fragment, sampler: { type: :filtering } }
      ])
      expect(layout).to be_a(WGPU::BindGroupLayout)
      layout.release
    end

    it "creates a bind group layout with texture binding" do
      layout = device.create_bind_group_layout(entries: [
        { binding: 0, visibility: :fragment, texture: { sample_type: :float, view_dimension: :d2 } }
      ])
      expect(layout).to be_a(WGPU::BindGroupLayout)
      layout.release
    end
  end

  describe "#release" do
    it "releases the bind group layout" do
      layout = device.create_bind_group_layout(entries: [
        { binding: 0, visibility: :compute, buffer: { type: :storage } }
      ])
      layout.release
      expect(layout.handle).to be_null
    end
  end
end

RSpec.describe WGPU::BindGroup, :gpu do
  let(:instance) { WGPU::Instance.new }
  let(:adapter) { instance.request_adapter }
  let(:device) { adapter.request_device }

  after do
    device.release
    adapter.release
    instance.release
  end

  describe "#initialize" do
    it "creates a bind group with buffer" do
      buffer = device.create_buffer(size: 256, usage: :storage)
      layout = device.create_bind_group_layout(entries: [
        { binding: 0, visibility: :compute, buffer: { type: :storage } }
      ])
      bind_group = device.create_bind_group(
        layout: layout,
        entries: [{ binding: 0, buffer: buffer }]
      )
      expect(bind_group).to be_a(WGPU::BindGroup)
      expect(bind_group.handle).not_to be_null

      bind_group.release
      layout.release
      buffer.release
    end

    it "creates a bind group with label" do
      buffer = device.create_buffer(size: 256, usage: :storage)
      layout = device.create_bind_group_layout(entries: [
        { binding: 0, visibility: :compute, buffer: { type: :storage } }
      ])
      bind_group = device.create_bind_group(
        label: "test bind group",
        layout: layout,
        entries: [{ binding: 0, buffer: buffer }]
      )
      expect(bind_group.handle).not_to be_null

      bind_group.release
      layout.release
      buffer.release
    end

    it "creates a bind group with multiple buffers" do
      buffer1 = device.create_buffer(size: 256, usage: :storage)
      buffer2 = device.create_buffer(size: 256, usage: :storage)
      layout = device.create_bind_group_layout(entries: [
        { binding: 0, visibility: :compute, buffer: { type: :storage } },
        { binding: 1, visibility: :compute, buffer: { type: :storage } }
      ])
      bind_group = device.create_bind_group(
        layout: layout,
        entries: [
          { binding: 0, buffer: buffer1 },
          { binding: 1, buffer: buffer2 }
        ]
      )
      expect(bind_group).to be_a(WGPU::BindGroup)

      bind_group.release
      layout.release
      buffer1.release
      buffer2.release
    end

    it "creates a bind group with sampler" do
      sampler = device.create_sampler
      layout = device.create_bind_group_layout(entries: [
        { binding: 0, visibility: :fragment, sampler: { type: :filtering } }
      ])
      bind_group = device.create_bind_group(
        layout: layout,
        entries: [{ binding: 0, sampler: sampler }]
      )
      expect(bind_group).to be_a(WGPU::BindGroup)

      bind_group.release
      layout.release
      sampler.release
    end

    it "creates a bind group with texture view" do
      texture = device.create_texture(
        size: { width: 64, height: 64 },
        format: :rgba8_unorm,
        usage: :texture_binding
      )
      view = texture.create_view
      layout = device.create_bind_group_layout(entries: [
        { binding: 0, visibility: :fragment, texture: { sample_type: :float, view_dimension: :d2 } }
      ])
      bind_group = device.create_bind_group(
        layout: layout,
        entries: [{ binding: 0, texture_view: view }]
      )
      expect(bind_group).to be_a(WGPU::BindGroup)

      bind_group.release
      layout.release
      view.release
      texture.release
    end
  end

  describe "#release" do
    it "releases the bind group" do
      buffer = device.create_buffer(size: 256, usage: :storage)
      layout = device.create_bind_group_layout(entries: [
        { binding: 0, visibility: :compute, buffer: { type: :storage } }
      ])
      bind_group = device.create_bind_group(
        layout: layout,
        entries: [{ binding: 0, buffer: buffer }]
      )
      bind_group.release
      expect(bind_group.handle).to be_null

      layout.release
      buffer.release
    end
  end
end
