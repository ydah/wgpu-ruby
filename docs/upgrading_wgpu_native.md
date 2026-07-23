# Upgrading wgpu-native

Use this checklist for each pinned wgpu-native update.

1. Update only `WGPU::Native::Distribution::VERSION`.
2. Obtain the five release artifact names and SHA-256 digests from the official
   wgpu-native GitHub release. Update `ARTIFACTS`.
3. Run `rg` for the old version and confirm no second version definition
   remains.
4. Run `bundle exec rake wgpu:clean wgpu:install` on a disposable cache, then
   test an existing legacy cache separately.
5. Run `bundle exec rake wgpu:verify_abi`. Review every enum addition, removal,
   and value change against the checksum-pinned `webgpu.h`.
6. Compare structs, field offsets, callback signatures, and exported functions.
   Add ABI specs for changed layouts. Mark functions optional only when the Ruby
   API has a valid capability fallback.
7. Run `bundle exec rspec --tag '~gpu'`, RuboCop, RBS validation, and YARD.
8. Run every `:gpu` spec and `rake examples:ci` with lavapipe. Run rendering
   examples on at least one real surface backend.
9. Build the gem and install it into a clean environment without SDL3.
10. Record ABI/API changes, platform artifacts, and migration notes in
    `CHANGELOG.md`.

For a dry run, use a temporary `WGPU_CACHE_DIR` and restore the version/artifact
edits afterward. Never replace the shared user cache as part of verification.

