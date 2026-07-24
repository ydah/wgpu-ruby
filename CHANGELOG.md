# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

## 1.2.1 - 2026-07-24

### Added

- Add reusable staging buffers to `Queue#read_buffer` and
  `Queue#read_texture`, together with a padded texture-readback example and
  guide.
- Support WGSL override constants and omitted entry points across compute,
  vertex, and fragment pipeline stages.
- Add a pinned wgpu-native v27.0.4.0 header fixture, ABI update tooling, and
  cross-platform native artifact verification.
- Complete RBS and YARD coverage for the public API and expand acceptance
  coverage for typed buffers, descriptors, errors, timeouts, resource
  lifetimes, and GPU examples.

### Changed

- Centralize native capability metadata and validate enum, callback, struct,
  and function ABI expectations against the pinned wgpu-native release.
- Make compute and rendering examples verify their results, and enforce
  documentation coverage, SDL3-free installation, release checks, and strict
  lavapipe GPU coverage in CI.

### Fixed

- Retain callbacks, user data, devices, and instances through dependent
  resource and pending-operation lifetimes, preventing use-after-free crashes
  after release, garbage collection, or timeout.
- Reject out-of-bounds mapped ranges and prevent late buffer, queue, shader,
  and error-scope callbacks from corrupting completed operation state.
- Preserve row padding and clean up temporary resources during buffer and
  texture readback, including repeated reads with caller-owned staging buffers.
- Recover rendering loops from timed-out, outdated, and lost surface frames,
  report fatal acquisition states explicitly, and release every acquired
  texture and view.
- Track adopted native handles in leak diagnostics and keep release operations
  idempotent across wrapper types.
- Correct the isolated core-gem dependency path and make Windows native
  artifact checks independent of shell quoting.

## 1.2.0 - 2026-07-23

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
