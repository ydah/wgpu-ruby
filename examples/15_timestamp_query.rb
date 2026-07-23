# frozen_string_literal: true

# Purpose: resolve beginning/end timestamps from an otherwise empty GPU pass.
# APIs: QuerySet, timestamp_writes, resolve_query_set, Queue#read_buffer.
# Expected: prints a non-negative tick delta, or an explicit unsupported skip.

require_relative "../lib/wgpu"

resources = []
instance = WGPU::Instance.new
adapter = instance.request_adapter(timeout: 10)

begin
  unless adapter.has_feature?(:timestamp_query)
    puts "Timestamp query SKIPPED: adapter does not support :timestamp_query"
    exit
  end

  device = adapter.request_device(required_features: [:timestamp_query], timeout: 10)
  query_set = device.create_query_set(label: "example timestamps", type: :timestamp, count: 2)
  resources << query_set
  resolve_buffer = device.create_buffer(
    label: "timestamp resolve",
    size: 16,
    usage: %i[query_resolve copy_src]
  )
  resources << resolve_buffer
  encoder = device.create_command_encoder
  resources << encoder
  encoder.begin_compute_pass(
    timestamp_writes: {
      query_set: query_set,
      beginning_of_pass_write_index: 0,
      end_of_pass_write_index: 1
    }
  ) {}
  encoder.resolve_query_set(
    query_set: query_set,
    first_query: 0,
    query_count: 2,
    destination: resolve_buffer,
    destination_offset: 0
  )
  command_buffer = encoder.finish
  resources << command_buffer
  device.queue.submit(command_buffer)

  start_tick, end_tick = device.queue.read_buffer(resolve_buffer).unpack("Q<2")
  abort "timestamp order is invalid" if end_tick < start_tick

  puts "Timestamp delta: #{end_tick - start_tick} ticks"
  puts "Timestamp query PASSED"
ensure
  query_set&.destroy unless query_set&.released?
  resources&.reverse_each { |resource| resource.release unless resource.released? }
  device&.release unless device&.released?
  adapter&.release unless adapter&.released?
  instance&.release unless instance&.released?
end
