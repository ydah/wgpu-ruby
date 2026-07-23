# Releasing

The release workflow uses RubyGems Trusted Publishing and runs for `v*` tags.
Before the first automated release, configure a trusted publisher for the
`ydah/wgpu-ruby` repository, workflow `release.yml`, and GitHub environment
`release` on RubyGems.org.

Release checklist:

1. Complete the [wgpu-native upgrade checklist](upgrading_wgpu_native.md) when
   the native version changes.
2. Update `WGPU::VERSION` and move Unreleased changelog entries under the new
   version/date heading.
3. Run the complete local verification documented in the project README.
4. Build and inspect the gem: `gem build wgpu.gemspec`.
5. Merge the release commit, create an annotated `vX.Y.Z` tag, and push it.
6. Confirm CI and the protected `release` environment. The workflow rejects a
   tag that does not equal `v#{WGPU::VERSION}`.
7. Verify the published gem and generated documentation on RubyGems.org.

The workflow requests only `contents: write` and `id-token: write`; it stores no
long-lived RubyGems API key.
