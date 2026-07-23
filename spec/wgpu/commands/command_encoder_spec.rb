# frozen_string_literal: true

RSpec.describe WGPU::CommandEncoder, :gpu do
  let(:instance) { WGPU::Instance.new }
  let(:adapter) { instance.request_adapter }
  let(:device) { adapter.request_device }

  after do
    device.release
    adapter.release
    instance.release
  end

  describe "#finish" do
    it "returns a command buffer" do
      encoder = device.create_command_encoder
      buffer = encoder.finish
      expect(buffer).to be_a(WGPU::CommandBuffer)
    end

    it "raises error if already finished" do
      encoder = device.create_command_encoder
      encoder.finish
      expect { encoder.finish }.to raise_error(WGPU::CommandError)
    end
  end

  describe "#copy_buffer_to_buffer" do
    it "copies data between buffers" do
      source = device.create_buffer_with_data(data: [1.0, 2.0, 3.0, 4.0], usage: [:storage, :copy_src])
      dest = device.create_buffer(size: 16, usage: [:storage, :copy_dst])

      encoder = device.create_command_encoder
      encoder.copy_buffer_to_buffer(
        source: source,
        source_offset: 0,
        destination: dest,
        destination_offset: 0,
        size: 16
      )
      command_buffer = encoder.finish
      device.queue.submit([command_buffer])
      device.poll(wait: true)

      source.release
      dest.release
    end

    it "copies with offsets" do
      source = device.create_buffer_with_data(data: [1.0, 2.0, 3.0, 4.0], usage: [:storage, :copy_src])
      dest = device.create_buffer(size: 32, usage: [:storage, :copy_dst])

      encoder = device.create_command_encoder
      encoder.copy_buffer_to_buffer(
        source: source,
        source_offset: 4,
        destination: dest,
        destination_offset: 8,
        size: 8
      )
      command_buffer = encoder.finish
      device.queue.submit([command_buffer])

      source.release
      dest.release
    end
  end

  describe "#copy_buffer_to_texture" do
    it "copies buffer to texture" do
      buffer = device.create_buffer_with_data(
        data: "\xFF\x00\x00\xFF" * (64 * 64),
        usage: [:copy_src]
      )
      texture = device.create_texture(
        size: { width: 64, height: 64 },
        format: :rgba8_unorm,
        usage: [:texture_binding, :copy_dst]
      )

      encoder = device.create_command_encoder
      encoder.copy_buffer_to_texture(
        source: { buffer: buffer, bytes_per_row: 256 },
        destination: { texture: texture },
        copy_size: { width: 64, height: 64 }
      )
      command_buffer = encoder.finish
      device.queue.submit([command_buffer])

      buffer.release
      texture.release
    end
  end

  describe "#copy_texture_to_buffer" do
    it "copies texture to buffer" do
      texture = device.create_texture(
        size: { width: 64, height: 64 },
        format: :rgba8_unorm,
        usage: [:texture_binding, :copy_dst, :copy_src]
      )
      device.queue.write_texture(
        destination: { texture: texture },
        data: "\xFF\x00\x00\xFF" * (64 * 64),
        data_layout: { bytes_per_row: 256 },
        size: { width: 64, height: 64 }
      )

      buffer = device.create_buffer(size: 256 * 64, usage: [:copy_dst])

      encoder = device.create_command_encoder
      encoder.copy_texture_to_buffer(
        source: { texture: texture },
        destination: { buffer: buffer, bytes_per_row: 256 },
        copy_size: { width: 64, height: 64 }
      )
      command_buffer = encoder.finish
      device.queue.submit([command_buffer])

      texture.release
      buffer.release
    end
  end

  describe "#copy_texture_to_texture" do
    it "copies between textures" do
      source = device.create_texture(
        size: { width: 64, height: 64 },
        format: :rgba8_unorm,
        usage: [:texture_binding, :copy_dst, :copy_src]
      )
      device.queue.write_texture(
        destination: { texture: source },
        data: "\xFF\x00\x00\xFF" * (64 * 64),
        data_layout: { bytes_per_row: 256 },
        size: { width: 64, height: 64 }
      )

      dest = device.create_texture(
        size: { width: 64, height: 64 },
        format: :rgba8_unorm,
        usage: [:texture_binding, :copy_dst]
      )

      encoder = device.create_command_encoder
      encoder.copy_texture_to_texture(
        source: { texture: source },
        destination: { texture: dest },
        copy_size: { width: 64, height: 64 }
      )
      command_buffer = encoder.finish
      device.queue.submit([command_buffer])

      source.release
      dest.release
    end

    it "copies with origin offsets" do
      source = device.create_texture(
        size: { width: 128, height: 128 },
        format: :rgba8_unorm,
        usage: [:texture_binding, :copy_dst, :copy_src]
      )
      dest = device.create_texture(
        size: { width: 128, height: 128 },
        format: :rgba8_unorm,
        usage: [:texture_binding, :copy_dst]
      )

      encoder = device.create_command_encoder
      encoder.copy_texture_to_texture(
        source: { texture: source, origin: { x: 32, y: 32, z: 0 } },
        destination: { texture: dest, origin: { x: 0, y: 0, z: 0 } },
        copy_size: { width: 64, height: 64 }
      )
      command_buffer = encoder.finish
      device.queue.submit([command_buffer])

      source.release
      dest.release
    end
  end

  describe "#begin_compute_pass" do
    it "creates a compute pass" do
      encoder = device.create_command_encoder
      pass = encoder.begin_compute_pass
      expect(pass).to be_a(WGPU::ComputePass)
      pass.end_pass
      encoder.finish
    end

    it "accepts timestamp_writes when supported", :optional_feature do
      skip "timestamp_query not supported by adapter" unless adapter.features.include?(:timestamp_query)

      timestamp_device = begin
        adapter.request_device(required_features: [:timestamp_query])
      rescue WGPU::DeviceError => e
        skip "failed to request device with timestamp_query: #{e.message}"
      end

      query_set = timestamp_device.create_query_set(type: :timestamp, count: 2)
      encoder = timestamp_device.create_command_encoder
      pass = encoder.begin_compute_pass(
        timestamp_writes: {
          query_set: query_set,
          beginning_of_pass_write_index: 0,
          end_of_pass_write_index: 1
        }
      )
      expect(pass).to be_a(WGPU::ComputePass)
      pass.end
      encoder.finish
      query_set.release
      timestamp_device.release
    end
  end

  describe "#begin_render_pass" do
    it "creates a render pass" do
      texture = device.create_texture(
        size: { width: 64, height: 64 },
        format: :rgba8_unorm,
        usage: [:render_attachment]
      )
      view = texture.create_view

      encoder = device.create_command_encoder
      pass = encoder.begin_render_pass(
        color_attachments: [{
          view: view,
          load_op: :clear,
          store_op: :store,
          clear_value: { r: 0.0, g: 0.0, b: 0.0, a: 1.0 }
        }]
      )
      expect(pass).to be_a(WGPU::RenderPass)
      pass.end_pass
      encoder.finish

      view.release
      texture.release
    end

    it "accepts occlusion_query_set" do
      texture = device.create_texture(
        size: { width: 64, height: 64 },
        format: :rgba8_unorm,
        usage: [:render_attachment]
      )
      view = texture.create_view
      query_set = device.create_query_set(type: :occlusion, count: 4)

      encoder = device.create_command_encoder
      pass = encoder.begin_render_pass(
        color_attachments: [{
          view: view,
          load_op: :clear,
          store_op: :store,
          clear_value: { r: 0.0, g: 0.0, b: 0.0, a: 1.0 }
        }],
        occlusion_query_set: query_set
      )
      expect(pass).to be_a(WGPU::RenderPass)
      pass.end
      encoder.finish

      query_set.release
      view.release
      texture.release
    end
  end
end
