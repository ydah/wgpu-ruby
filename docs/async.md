# Async operations and polling

wgpu-native v27 returns futures for adapter/device requests, buffer mapping,
error scopes, compilation info, and queue completion. wgpu-ruby keeps callback
objects alive until each operation finishes and selects the best available
progress mechanism:

1. zero-time `wgpuInstanceWaitAny` polling;
2. `Instance#process_events`;
3. `Device#poll`;
4. a short Ruby sleep when native polling cannot block.

wgpu-native v27 aborts when its unsupported timed-WaitAny instance feature is
requested, so wgpu-ruby deliberately leaves that feature disabled. The Ruby
poll interval defaults to 1 ms and can be adjusted with
`WGPU::AsyncWaiter.poll_interval=`.

That release also exports `wgpuBufferGetMapState` as an unimplemented panic
stub. `Buffer#map_state` is maintained by wgpu-ruby as `:unmapped`,
`:pending`, or `:mapped` while map operations run.

Synchronous adapter/device requests, `Buffer#map_sync`,
`Device#pop_error_scope`, and `Queue#on_submitted_work_done` accept
`timeout:` in seconds. The default `nil` preserves the prior unbounded wait.
Expiry raises `WGPU::TimeoutError`.

`*_async` methods return `WGPU::AsyncTask`, a convenience wrapper backed by a
Ruby Thread. Concurrent operations on the same WebGPU object are not
guaranteed safe. Prefer synchronous operations or external serialization when
ordering matters. Rendering event loops should call `instance.process_events`
or `device.poll` regularly.
