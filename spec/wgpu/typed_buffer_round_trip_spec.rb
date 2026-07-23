# frozen_string_literal: true

RSpec.describe "typed buffer round trips", :gpu do
  let(:instance) { WGPU::Instance.new }
  let(:adapter) { instance.request_adapter }
  let(:device) { adapter.request_device }

  after do
    device.release
    adapter.release
    instance.release
  end

  {
    f32: [1.5, -2.25],
    f64: [1.5, -2.25],
    u32: [0, 0xFFFFFFFF],
    i32: [-1, 2],
    u16: [0, 65_535],
    u8: [0, 127, 128, 255]
  }.each do |type, values|
    it "creates, writes, reads back, and unpacks #{type}" do
      buffer = device.create_buffer_with_data(
        data: Array.new(values.length, 0),
        type: type,
        usage: %i[copy_src copy_dst]
      )

      device.queue.write_buffer(buffer, 0, values, type: type)
      bytes = device.queue.read_buffer(buffer)

      expect(WGPU::DataTypes.unpack(bytes, type: type)).to eq(values)
    ensure
      buffer&.release
    end
  end

  it "runs a u32 compute path without hand-packed input or output" do
    resources = []
    buffer = device.create_buffer_with_data(
      data: [1, 2, 3, 4],
      type: :u32,
      usage: %i[storage copy_src]
    )
    resources << buffer
    shader = device.create_shader_module(code: <<~WGSL)
      @group(0) @binding(0) var<storage, read_write> values: array<u32>;

      @compute @workgroup_size(1)
      fn main(@builtin(global_invocation_id) id: vec3<u32>) {
        values[id.x] = values[id.x] + 10u;
      }
    WGSL
    resources << shader
    pipeline = device.create_compute_pipeline(
      layout: :auto,
      compute: { module: shader, entry_point: "main" }
    )
    resources << pipeline
    layout = pipeline.get_bind_group_layout(0)
    resources << layout
    bind_group = device.create_bind_group(
      layout: layout,
      entries: [{ binding: 0, buffer: buffer }]
    )
    resources << bind_group
    encoder = device.create_command_encoder
    resources << encoder
    encoder.begin_compute_pass do |pass|
      pass.set_pipeline(pipeline)
      pass.set_bind_group(0, bind_group)
      pass.dispatch_workgroups(4)
    end
    command_buffer = encoder.finish
    resources << command_buffer
    device.queue.submit(command_buffer)

    result = device.queue.read_buffer(buffer)

    expect(WGPU::DataTypes.unpack(result, type: :u32)).to eq([11, 12, 13, 14])
  ensure
    resources&.reverse_each { |resource| resource.release unless resource.released? }
  end
end
