# Shader modules and diagnostics

WGSL remains the default input:

```ruby
shader = device.create_shader_module(code: wgsl, label: "simulation")
```

Pass `validate: true` to request compilation information immediately when the
loaded wgpu-native version implements that API. Error messages are raised as
`WGPU::ShaderError` with the shader label and line/column diagnostics. Without
this option, creation follows the original lazy validation behavior.

`ShaderModule#get_compilation_info` returns a Hash with `status:` and
`messages:`. Each message is a `WGPU::CompilationMessage` with `type`,
`message`, `line_num`/`line`, `line_pos`/`column`, `offset`, and `length`.

wgpu-native v27.0.4.0 exports the compilation-info function as an
unimplemented panic stub. wgpu-ruby detects that version and raises
`WGPU::ShaderError` before crossing the native boundary. This guard avoids a
process abort; diagnostics can be enabled when a future pinned wgpu-native
release implements the function.

wgpu-native's SPIR-V extension is available explicitly:

```ruby
shader = device.create_shader_module(spirv: binary_bytes, label: "compute")
```

SPIR-V input must contain a whole number of 32-bit words. It is a
wgpu-native extension rather than portable WebGPU API and should be avoided
when browser portability matters.
