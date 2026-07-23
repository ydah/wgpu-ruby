# frozen_string_literal: true

RSpec.describe "debug commands and block pass lifecycle", :gpu do
  let(:instance) { WGPU::Instance.new }
  let(:adapter) { instance.request_adapter }
  let(:device) { adapter.request_device }

  after do
    device.release
    adapter.release
    instance.release
  end

  it "records encoder, compute, render, and bundle debug commands" do
    resources = []
    texture = device.create_texture(
      size: { width: 4, height: 4 },
      format: :rgba8_unorm,
      usage: :render_attachment
    )
    resources << texture
    view = texture.create_view
    resources << view
    bundle_encoder = device.create_render_bundle_encoder(
      color_formats: [:rgba8_unorm]
    )
    resources << bundle_encoder
    bundle_encoder.push_debug_group("bundle group")
    bundle_encoder.insert_debug_marker("bundle marker")
    bundle_encoder.pop_debug_group
    bundle = bundle_encoder.finish
    resources << bundle

    encoder = device.create_command_encoder
    resources << encoder
    encoder.push_debug_group("encoder group")
    encoder.insert_debug_marker("encoder marker")
    encoder.pop_debug_group
    encoder.begin_compute_pass do |pass|
      pass.push_debug_group("compute group")
      pass.insert_debug_marker("compute marker")
      pass.pop_debug_group
    end
    encoder.begin_render_pass(
      color_attachments: [{
        view: view,
        load_op: :clear,
        store_op: :store
      }]
    ) do |pass|
      pass.push_debug_group("render group")
      pass.insert_debug_marker("render marker")
      pass.pop_debug_group
      pass.execute_bundles([bundle])
    end
    command_buffer = encoder.finish
    resources << command_buffer

    expect { device.queue.submit(command_buffer) }.not_to raise_error
    device.poll(wait: true)
  ensure
    resources&.reverse_each { |resource| resource.release unless resource.released? }
  end

  it "restores encoder state after a compute-pass block raises" do
    resources = []
    encoder = device.create_command_encoder
    resources << encoder

    expect do
      encoder.begin_compute_pass { raise "compute failure" }
    end.to raise_error("compute failure")

    command_buffer = encoder.finish
    resources << command_buffer
    expect { device.queue.submit(command_buffer) }.not_to raise_error
  ensure
    resources&.reverse_each { |resource| resource.release unless resource.released? }
  end

  it "restores encoder state after a render-pass block raises" do
    resources = []
    texture = device.create_texture(
      size: { width: 4, height: 4 },
      format: :rgba8_unorm,
      usage: :render_attachment
    )
    resources << texture
    view = texture.create_view
    resources << view
    encoder = device.create_command_encoder
    resources << encoder

    expect do
      encoder.begin_render_pass(
        color_attachments: [{
          view: view,
          load_op: :clear,
          store_op: :store
        }]
      ) { raise "render failure" }
    end.to raise_error("render failure")

    command_buffer = encoder.finish
    resources << command_buffer
    expect { device.queue.submit(command_buffer) }.not_to raise_error
  ensure
    resources&.reverse_each { |resource| resource.release unless resource.released? }
  end
end
