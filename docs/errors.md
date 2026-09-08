# GPU errors

`Device#pop_error_scope` keeps its v1.x Hash return value. New code may call
`pop_error_scope_typed`, which returns a `WGPU::GPUError` or `nil` for
`:no_error`.

`GPUError` has `type` and `message` readers, `to_h`, and `raise!`. `raise!`
maps WebGPU error types to `ValidationError`, `OutOfMemoryError`,
`InternalError`, or `DeviceLostError`.

`with_error_scope { ... }` always pops its scope, including when the block
raises; the original block exception is preserved. Popping without a scope
owned by the current thread raises `WGPU::DeviceError` before calling native
code.

Scopes are nested and serialized per device from push through native pop.
Push and pop on the same thread, and finish the scope before waiting for
another thread's scoped work on that device. In particular, do not wait for
an asynchronous pipeline creation inside `with_error_scope`.
`pop_error_scope_async` starts the pop immediately on the calling thread and
waits for its result in the background, so a later push cannot change which
scope it pops.

Device-level callbacks can be installed after device creation:

```ruby
device.on_uncaptured_error do |error|
  warn "#{error.type}: #{error.message}"
end

device.on_device_lost do |reason, message|
  warn "#{reason}: #{message}"
end
```

wgpu-ruby installs native dispatch callbacks when requesting the device and
keeps them alive until release. User handlers can therefore be replaced without
recreating the native device. Without a handler, uncaptured errors and
unexpected device loss are written as warnings. Exceptions raised by a user
handler are caught at the FFI boundary and reported as warnings rather than
escaping through native callback code.

wgpu-native's process-wide diagnostic log can be routed into an application:

```ruby
WGPU.on_log do |level, message|
  MyLogger.public_send(level == :warn ? :warn : :debug, message)
end
WGPU.log_level = :info
```

The callback is retained for the process lifetime (or until replaced), so a
Ruby GC cycle cannot invalidate the native callback pointer.
