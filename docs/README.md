# Documentation

- [Getting started: compute](getting_started_compute.md)
- [Getting started: rendering](getting_started_rendering.md)
- [API coverage](api_coverage.md)
- [Installation and native artifacts](installation.md)
- [Resource lifetime](resource_lifetime.md)
- [Async operations and polling](async.md)
- [GPU errors](errors.md)
- [Buffer data](buffer_data.md)
- [Texture readback](texture_readback.md)
- [Shaders and diagnostics](shaders.md)
- [Bind groups and layouts](bind_groups.md)
- [Pipeline descriptors](pipeline_descriptors.md)
- [Command encoding](command_encoding.md)
- [Troubleshooting](troubleshooting.md)
- [Upgrading wgpu-native](upgrading_wgpu_native.md)
- [Releasing](releasing.md)

Generated API documentation is built with `bundle exec yard doc`. Static API
signatures live in `sig/wgpu.rbs` and validate with
`bundle exec rbs -I sig validate`.
