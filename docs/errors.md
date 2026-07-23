# GPU errors

`Device#pop_error_scope` keeps its v1.x Hash return value. New code may call
`pop_error_scope_typed`, which returns a `WGPU::GPUError` or `nil` for
`:no_error`.

`GPUError` has `type` and `message` readers, `to_h`, and `raise!`. `raise!`
maps WebGPU error types to `ValidationError`, `OutOfMemoryError`,
`InternalError`, or `DeviceLostError`.

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
