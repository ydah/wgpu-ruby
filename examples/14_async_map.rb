# frozen_string_literal: true

# Purpose: map a GPU copy asynchronously while stressing callback retention.
# APIs: Buffer#map_async, AsyncTask#value, typed mapped reads.
# Expected: prints [10, 20, 30, 40] and "Async map PASSED".

require_relative "../lib/wgpu"

resources = []
instance = WGPU::Instance.new
adapter = instance.request_adapter(timeout: 10)
device = adapter.request_device(timeout: 10)

begin
  source = device.create_buffer_with_data(
    data: [10, 20, 30, 40],
    type: :u32,
    usage: %i[copy_src]
  )
  resources << source
  destination = device.create_buffer(size: 16, usage: %i[map_read copy_dst])
  resources << destination
  encoder = device.create_command_encoder
  resources << encoder
  encoder.copy_buffer_to_buffer(source: source, destination: destination, size: 16)
  command_buffer = encoder.finish
  resources << command_buffer
  device.queue.submit(command_buffer)

  task = destination.map_async(:read)
  GC.start
  task.value(timeout: 10)
  values = destination.read_mapped_values(type: :u32)
  abort "unexpected async-map result: #{values.inspect}" unless values == [10, 20, 30, 40]

  puts values.inspect
  puts "Async map PASSED"
ensure
  destination&.unmap if destination&.map_state == :mapped
  resources&.reverse_each { |resource| resource.release unless resource.released? }
  device&.release unless device&.released?
  adapter&.release unless adapter&.released?
  instance&.release unless instance&.released?
end
