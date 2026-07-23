# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### Added

- Add typed buffer data, texture layout, shader diagnostics, GPU errors, and
  synchronous timeout APIs.
- Add ensure-safe command pass blocks, auto pipeline layouts, resource guards,
  leak diagnostics, and callback keepalive.
- Add checksum-verified wgpu-native installation and ABI verification.
- Add headless rendering pixel verification, 3D/array texture round-trips,
  async/error/timestamp examples, and GPU CI coverage.
- Add block-scoped resource cleanup, native diagnostic logging, RBS
  signatures, YARD documentation, and Trusted Publishing release automation.

### Changed

- Make the SDL3 Ruby gem optional for compute-only users.
- Validate descriptor shapes, enum values, buffer alignment, and texture
  readback layout before native calls.
- Treat command buffers as consumed after submission and expose typed surface
  acquisition status.

### Fixed

- Correct `CompareFunction` values and add missing v27 surface status and
  vertex format enum entries discovered by header verification.
- Guard exported-but-unimplemented v27 functions before they can abort Ruby,
  expose native extension feature names, and avoid v27 query-set double
  removal after `destroy`.

## 1.1.0 - 2026-02-16

- Align bindings with wgpu v27 async ABI.
- Add shared async waiting for adapter/device.
- Migrate buffer/queue/shader async completion paths.

## 1.0.0 - 2026-02-15

- Initial release
