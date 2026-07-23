# frozen_string_literal: true

RSpec.describe "Compute Pipeline Integration", :gpu do
  let(:instance) { WGPU::Instance.new }
  let(:adapter) { instance.request_adapter }
  let(:device) { adapter.request_device }

  after do
    device.release
    adapter.release
    instance.release
  end

  describe "simple compute shader" do
    it "doubles values in a buffer" do
      shader = device.create_shader_module(code: <<~WGSL)
        @group(0) @binding(0) var<storage, read_write> data: array<f32>;

        @compute @workgroup_size(64)
        fn main(@builtin(global_invocation_id) id: vec3<u32>) {
          data[id.x] = data[id.x] * 2.0;
        }
      WGSL

      input_data = (0...64).map(&:to_f)
      buffer = device.create_buffer_with_data(
        data: input_data,
        usage: [:storage, :copy_src, :copy_dst]
      )

      bind_group_layout = device.create_bind_group_layout(entries: [
        { binding: 0, visibility: :compute, buffer: { type: :storage } }
      ])
      pipeline_layout = device.create_pipeline_layout(bind_group_layouts: [bind_group_layout])
      pipeline = device.create_compute_pipeline(
        layout: pipeline_layout,
        compute: { module: shader, entry_point: "main" }
      )
      bind_group = device.create_bind_group(
        layout: bind_group_layout,
        entries: [{ binding: 0, buffer: buffer }]
      )

      encoder = device.create_command_encoder
      pass = encoder.begin_compute_pass
      pass.set_pipeline(pipeline)
      pass.set_bind_group(0, bind_group)
      pass.dispatch_workgroups(1)
      pass.end_pass
      device.queue.submit([encoder.finish])
      device.poll(wait: true)

      result = device.queue.read_buffer(buffer, device: device)
      result_floats = result.unpack("f*")
      expected = input_data.map { |x| x * 2.0 }
      expect(result_floats).to eq(expected)

      bind_group.release
      pipeline.release
      pipeline_layout.release
      bind_group_layout.release
      buffer.release
      shader.release
    end

    it "applies override constants to compute results" do
      shader = device.create_shader_module(code: <<~WGSL)
        override multiplier: f32 = 1.0;
        @group(0) @binding(0) var<storage, read_write> data: array<f32>;

        @compute @workgroup_size(1)
        fn apply_multiplier() {
          data[0] *= multiplier;
        }
      WGSL
      buffer = device.create_buffer_with_data(
        data: [2.0],
        usage: [:storage, :copy_src]
      )
      bind_group_layout = device.create_bind_group_layout(entries: [
        { binding: 0, visibility: :compute, buffer: { type: :storage } }
      ])
      pipeline_layout = device.create_pipeline_layout(bind_group_layouts: [bind_group_layout])
      pipeline = device.create_compute_pipeline(
        layout: pipeline_layout,
        compute: {
          module: shader,
          entry_point: "apply_multiplier",
          constants: { multiplier: 3.0 }
        }
      )
      bind_group = device.create_bind_group(
        layout: bind_group_layout,
        entries: [{ binding: 0, buffer: buffer }]
      )

      encoder = device.create_command_encoder
      pass = encoder.begin_compute_pass
      pass.set_pipeline(pipeline)
      pass.set_bind_group(0, bind_group)
      pass.dispatch_workgroups(1)
      pass.end_pass
      command_buffer = encoder.finish
      device.queue.submit([command_buffer])
      device.poll(wait: true)

      result = device.queue.read_buffer(buffer, device: device)
      expect(result.unpack1("f")).to eq(6.0)

      command_buffer.release
      pass.release
      encoder.release
      bind_group.release
      pipeline.release
      pipeline_layout.release
      bind_group_layout.release
      buffer.release
      shader.release
    end

    it "adds two buffers element-wise" do
      shader = device.create_shader_module(code: <<~WGSL)
        @group(0) @binding(0) var<storage, read> a: array<f32>;
        @group(0) @binding(1) var<storage, read> b: array<f32>;
        @group(0) @binding(2) var<storage, read_write> result: array<f32>;

        @compute @workgroup_size(64)
        fn main(@builtin(global_invocation_id) id: vec3<u32>) {
          result[id.x] = a[id.x] + b[id.x];
        }
      WGSL

      data_a = (0...64).map(&:to_f)
      data_b = (0...64).map { |i| i * 10.0 }
      buffer_a = device.create_buffer_with_data(data: data_a, usage: [:storage])
      buffer_b = device.create_buffer_with_data(data: data_b, usage: [:storage])
      buffer_result = device.create_buffer(size: 64 * 4, usage: [:storage, :copy_src])

      bind_group_layout = device.create_bind_group_layout(entries: [
        { binding: 0, visibility: :compute, buffer: { type: :read_only_storage } },
        { binding: 1, visibility: :compute, buffer: { type: :read_only_storage } },
        { binding: 2, visibility: :compute, buffer: { type: :storage } }
      ])
      pipeline_layout = device.create_pipeline_layout(bind_group_layouts: [bind_group_layout])
      pipeline = device.create_compute_pipeline(
        layout: pipeline_layout,
        compute: { module: shader, entry_point: "main" }
      )
      bind_group = device.create_bind_group(
        layout: bind_group_layout,
        entries: [
          { binding: 0, buffer: buffer_a },
          { binding: 1, buffer: buffer_b },
          { binding: 2, buffer: buffer_result }
        ]
      )

      encoder = device.create_command_encoder
      pass = encoder.begin_compute_pass
      pass.set_pipeline(pipeline)
      pass.set_bind_group(0, bind_group)
      pass.dispatch_workgroups(1)
      pass.end_pass
      device.queue.submit([encoder.finish])
      device.poll(wait: true)

      result = device.queue.read_buffer(buffer_result, device: device)
      result_floats = result.unpack("f*")
      expected = data_a.zip(data_b).map { |a, b| a + b }
      expect(result_floats).to eq(expected)

      bind_group.release
      pipeline.release
      pipeline_layout.release
      bind_group_layout.release
      buffer_result.release
      buffer_b.release
      buffer_a.release
      shader.release
    end
  end

  describe "buffer data roundtrip" do
    it "writes and reads back float data correctly" do
      input_data = [1.5, 2.5, 3.5, 4.5, 5.5, 6.5, 7.5, 8.5]
      buffer = device.create_buffer_with_data(
        data: input_data,
        usage: [:storage, :copy_src]
      )
      device.poll(wait: true)

      result = device.queue.read_buffer(buffer, device: device)
      result_floats = result.unpack("f*")
      expect(result_floats).to eq(input_data)

      buffer.release
    end

    it "writes and reads back integer data correctly" do
      input_data = [1, 2, 3, 4, 5, 6, 7, 8].pack("i*")
      buffer = device.create_buffer_with_data(
        data: input_data,
        usage: [:storage, :copy_src]
      )
      device.poll(wait: true)

      result = device.queue.read_buffer(buffer, device: device)
      expect(result.unpack("i*")).to eq([1, 2, 3, 4, 5, 6, 7, 8])

      buffer.release
    end
  end

  describe "buffer copy operations" do
    it "copies data between buffers correctly" do
      input_data = [10.0, 20.0, 30.0, 40.0]
      source = device.create_buffer_with_data(
        data: input_data,
        usage: [:storage, :copy_src]
      )
      dest = device.create_buffer(size: 16, usage: [:storage, :copy_dst, :copy_src])

      encoder = device.create_command_encoder
      encoder.copy_buffer_to_buffer(source: source, destination: dest, size: 16)
      device.queue.submit([encoder.finish])
      device.poll(wait: true)

      result = device.queue.read_buffer(dest, device: device)
      result_floats = result.unpack("f*")
      expect(result_floats).to eq(input_data)

      source.release
      dest.release
    end

    it "copies partial data with offsets" do
      input_data = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0]
      source = device.create_buffer_with_data(
        data: input_data,
        usage: [:storage, :copy_src]
      )
      dest = device.create_buffer(size: 32, usage: [:storage, :copy_dst, :copy_src])
      device.queue.write_buffer(dest, 0, [0.0] * 8)

      encoder = device.create_command_encoder
      encoder.copy_buffer_to_buffer(
        source: source,
        source_offset: 8,
        destination: dest,
        destination_offset: 16,
        size: 8
      )
      device.queue.submit([encoder.finish])
      device.poll(wait: true)

      result = device.queue.read_buffer(dest, device: device)
      result_floats = result.unpack("f*")
      expect(result_floats[4]).to eq(3.0)
      expect(result_floats[5]).to eq(4.0)

      source.release
      dest.release
    end
  end

  describe "multiple workgroups" do
    it "processes large data with multiple workgroups" do
      shader = device.create_shader_module(code: <<~WGSL)
        @group(0) @binding(0) var<storage, read_write> data: array<f32>;

        @compute @workgroup_size(64)
        fn main(@builtin(global_invocation_id) id: vec3<u32>) {
          data[id.x] = data[id.x] + 1.0;
        }
      WGSL

      size = 256
      input_data = (0...size).map(&:to_f)
      buffer = device.create_buffer_with_data(
        data: input_data,
        usage: [:storage, :copy_src, :copy_dst]
      )

      bind_group_layout = device.create_bind_group_layout(entries: [
        { binding: 0, visibility: :compute, buffer: { type: :storage } }
      ])
      pipeline_layout = device.create_pipeline_layout(bind_group_layouts: [bind_group_layout])
      pipeline = device.create_compute_pipeline(
        layout: pipeline_layout,
        compute: { module: shader, entry_point: "main" }
      )
      bind_group = device.create_bind_group(
        layout: bind_group_layout,
        entries: [{ binding: 0, buffer: buffer }]
      )

      encoder = device.create_command_encoder
      pass = encoder.begin_compute_pass
      pass.set_pipeline(pipeline)
      pass.set_bind_group(0, bind_group)
      pass.dispatch_workgroups(size / 64)
      pass.end_pass
      device.queue.submit([encoder.finish])
      device.poll(wait: true)

      result = device.queue.read_buffer(buffer, device: device)
      result_floats = result.unpack("f*")
      expected = input_data.map { |x| x + 1.0 }
      expect(result_floats).to eq(expected)

      bind_group.release
      pipeline.release
      pipeline_layout.release
      bind_group_layout.release
      buffer.release
      shader.release
    end
  end
end
