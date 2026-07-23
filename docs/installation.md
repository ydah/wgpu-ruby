# Installation and native artifacts

wgpu-ruby is a Ruby-FFI binding. Gem installation downloads a prebuilt
wgpu-native library; it does not compile a C extension.

## Supported runtime

- Ruby 3.2 or newer
- 64-bit macOS x86_64/arm64
- 64-bit Linux glibc x86_64/aarch64
- 64-bit Windows x86_64 with the MSVC wgpu-native artifact

Linux musl/Alpine and 32-bit runtimes do not have prebuilt artifacts. They may
still work with a compatible custom library supplied through `WGPU_LIB_PATH`.

## Pinned release and artifacts

The binding targets wgpu-native `v27.0.4.0` from:

`https://github.com/gfx-rs/wgpu-native/releases/download/v27.0.4.0/`

| Ruby platform | Archive | Library |
|---|---|---|
| `x86_64-linux` | `wgpu-linux-x86_64-release.zip` | `libwgpu_native.so` |
| `aarch64-linux` | `wgpu-linux-aarch64-release.zip` | `libwgpu_native.so` |
| `x86_64-darwin` | `wgpu-macos-x86_64-release.zip` | `libwgpu_native.dylib` |
| `arm64-darwin` | `wgpu-macos-aarch64-release.zip` | `libwgpu_native.dylib` |
| Windows `mingw`/`mswin` | `wgpu-windows-x86_64-msvc-release.zip` | `wgpu_native.dll` |

## Resolution order

1. If `WGPU_LIB_PATH` is set, installation skips the download and runtime
   loading uses that exact file.
2. Otherwise the runtime looks for the platform library under
   `~/.cache/wgpu-ruby/v27.0.4.0/lib/`.
3. If the cached library is absent, reinstall the gem or run
   `bundle exec ruby ext/wgpu/extconf.rb` from a source checkout.

Download uses `curl` when available, then Ruby `Net::HTTP`. Extraction uses
`rubyzip`, then PowerShell `Expand-Archive` on Windows, then `unzip`.

## Manual installation

1. Download the archive for the target above.
2. Extract it and locate the library in the archive's `lib` directory.
3. Set `WGPU_LIB_PATH` to the absolute library path before starting Ruby:

```bash
export WGPU_LIB_PATH=/opt/wgpu-native/lib/libwgpu_native.so
bundle exec ruby -Ilib -e 'require "wgpu"; puts WGPU::Native.library_path'
```

PowerShell:

```powershell
$env:WGPU_LIB_PATH = "C:\wgpu-native\lib\wgpu_native.dll"
bundle exec ruby -Ilib -e 'require "wgpu"; puts WGPU::Native.library_path'
```

The library must match the process architecture and the v27 ABI expected by
this gem.

## Environment variables

| Variable | Meaning |
|---|---|
| `WGPU_LIB_PATH` | Absolute path to a custom wgpu-native shared library; highest priority. |
| `WGPU_SKIP_GPU_TESTS=1` | Skip tests that require an adapter. This is a test setting, not a runtime backend selector. |

## Troubleshooting

- **Library not found:** rerun the install hook or set `WGPU_LIB_PATH`.
- **Unsupported platform:** build wgpu-native for the host and use
  `WGPU_LIB_PATH`.
- **Linux cannot create an adapter:** install a Vulkan driver. Mesa lavapipe
  (`mesa-vulkan-drivers`) is sufficient for software-based tests.
- **Rendering examples fail to load SDL3:** install the SDL3 system library and
  the `sdl3` Ruby gem. Compute APIs do not load `wgpu/window`.
