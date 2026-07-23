# Upgrading wgpu-native

Use this checklist for each pinned wgpu-native update.

1. Update only `WGPU::Native::Distribution::VERSION`.
2. Obtain the five release artifact names and SHA-256 digests from the official
   wgpu-native GitHub release. Update `ARTIFACTS`.
3. Run `rg` for the old version and confirm no second version definition
   remains.
4. Run `bundle exec rake wgpu:clean wgpu:install` on a disposable cache, then
   test an existing legacy cache separately.
5. Regenerate the repository enum fixture from the installed release header:

   ```console
   bundle exec ruby script/update_abi_fixture.rb \
     "$WGPU_CACHE_DIR/<version>/include/webgpu/webgpu.h"
   ```

   The generated comment records the source SHA-256. For the current
   `v27.0.4.0` release, `include/webgpu/webgpu.h` is
   `a6fccf7f9f2fa674d1adfe4f6ea89784a876395b2307bfc2b06f2e77cf6cf356`.
   Review every enum addition, removal, and value change, then run
   `bundle exec rake wgpu:verify_abi`.
6. Compare structs, field offsets, callback signatures, and exported functions.
   Add ABI specs for changed layouts. Check `include/webgpu/wgpu.h` for native
   extensions as well. `wgpuGetVersion` encodes `vMAJOR.MINOR.PATCH.BUILD` in
   four bytes; the verifier compares it with `Distribution::VERSION`. Mark
   functions optional only when the Ruby API has a valid capability fallback.
7. Run `bundle exec rspec --tag '~gpu'`, RuboCop, RBS validation, and YARD.
8. Run every `:gpu` spec and `rake examples:ci` with lavapipe. Run rendering
   examples on at least one real surface backend.
9. Build the gem and install it into a clean environment without SDL3.
10. Record ABI/API changes, platform artifacts, and migration notes in
    `CHANGELOG.md`.

For a dry run, use a temporary `WGPU_CACHE_DIR` and restore the version/artifact
edits afterward. Never replace the shared user cache as part of verification.
