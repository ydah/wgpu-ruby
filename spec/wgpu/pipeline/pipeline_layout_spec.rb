# frozen_string_literal: true

RSpec.describe WGPU::PipelineLayout, :gpu do
  let(:instance) { WGPU::Instance.new }
  let(:adapter) { instance.request_adapter }
  let(:device) { adapter.request_device }

  after do
    device.release
    adapter.release
    instance.release
  end

  describe "#initialize" do
    it "creates a pipeline layout with no bind group layouts" do
      layout = device.create_pipeline_layout(bind_group_layouts: [])
      expect(layout).to be_a(WGPU::PipelineLayout)
      expect(layout.handle).not_to be_null
      layout.release
    end

    it "creates a pipeline layout with label" do
      layout = device.create_pipeline_layout(
        label: "test pipeline layout",
        bind_group_layouts: []
      )
      expect(layout.handle).not_to be_null
      layout.release
    end

    it "creates a pipeline layout with single bind group layout" do
      bind_group_layout = device.create_bind_group_layout(entries: [
        { binding: 0, visibility: :compute, buffer: { type: :storage } }
      ])
      layout = device.create_pipeline_layout(bind_group_layouts: [bind_group_layout])
      expect(layout).to be_a(WGPU::PipelineLayout)

      layout.release
      bind_group_layout.release
    end

    it "creates a pipeline layout with multiple bind group layouts" do
      bind_group_layout1 = device.create_bind_group_layout(entries: [
        { binding: 0, visibility: :compute, buffer: { type: :storage } }
      ])
      bind_group_layout2 = device.create_bind_group_layout(entries: [
        { binding: 0, visibility: :compute, buffer: { type: :uniform } }
      ])
      layout = device.create_pipeline_layout(
        bind_group_layouts: [bind_group_layout1, bind_group_layout2]
      )
      expect(layout).to be_a(WGPU::PipelineLayout)

      layout.release
      bind_group_layout1.release
      bind_group_layout2.release
    end

    it "accepts a single bind group layout without array" do
      bind_group_layout = device.create_bind_group_layout(entries: [
        { binding: 0, visibility: :compute, buffer: { type: :storage } }
      ])
      layout = device.create_pipeline_layout(bind_group_layouts: bind_group_layout)
      expect(layout).to be_a(WGPU::PipelineLayout)

      layout.release
      bind_group_layout.release
    end
  end

  describe "#release" do
    it "releases the pipeline layout" do
      layout = device.create_pipeline_layout(bind_group_layouts: [])
      layout.release
      expect(layout.handle).to be_null
    end

    it "can be called multiple times" do
      layout = device.create_pipeline_layout(bind_group_layouts: [])
      layout.release
      expect { layout.release }.not_to raise_error
    end
  end
end
