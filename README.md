# av-enc

Encoding scripts for my media library.

## Dependencies

Install these dependencies:

- `ab-av1`
- `ffmpeg` with at least the following features:
  - `--enable-libsvtav1`
  - `--enable-libvmaf`
  - might be more? who knows, just use the full `ffmpeg`
    package your distro provides.
- `coreutils`
- `ripgrep`

Alternatively, the Nix flake provides everything you need.
