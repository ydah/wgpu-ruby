# Shader modules and diagnostics

WGSL remains the default input:

```ruby
shader = device.create_shader_module(code: wgsl, label: "simulation")
```

Pass `validate: true` to request compilation information immediately. Error
messages are raised as `WGPU::ShaderError` with the shader label and
line/column diagnostics. Without this option, creation follows the original
lazy validation behavior.

`ShaderModule#get_compilation_info` returns a Hash with `status:` and
`messages:`. Each message is a `WGPU::CompilationMessage` with `type`,
`message`, `line_num`/`line`, `line_pos`/`column`, `offset`, and `length`.

wgpu-native's SPIR-V extension is available explicitly:

```ruby
shader = device.create_shader_module(spirv: binary_bytes, label: "compute")
```

SPIR-V input must contain a whole number of 32-bit words. It is a
wgpu-native extension rather than portable WebGPU API and should be avoided
when browser portability matters.
