# Building a Bazzite-ready Linux bundle on macOS

The dev container builds an **x86_64 Linux** release bundle, even on this
Apple-silicon Mac. It matches the upstream project's Linux CI baseline:
Ubuntu 20.04, Flutter 3.35.1, GTK 3, and Ninja.

It is a build environment only. Run and test the resulting bundle on the
Bazzite PC, where Steam Big Picture and the 8BitDo controller are available.

## Build

Open this repository in its `Jackbox Utility Linux (x86_64)` dev container,
then run:

```bash
./scripts/build-linux-amd64.sh
```

The finished application bundle is:

```text
jackbox_patcher/build/linux/x64/release/bundle
```

Copy that entire `bundle` directory to Bazzite. Start the executable inside
it with `--tv-mode`, then add that command as a non-Steam game in Steam.

## Expected timing

The first build downloads Flutter and Dart dependencies and runs x86_64 Linux
under Apple-silicon emulation, so expect roughly 10–25 minutes. Later source
builds reuse Docker and Flutter caches and should normally take a few minutes,
not hours.

## Other platforms

Flutter's desktop runners must be built on their native operating systems:

- Linux x86_64: this dev container.
- macOS: build natively on this Mac with the macOS Flutter toolchain.
- Windows: use a Windows machine or the existing GitHub Actions workflow.

The Linux container is intentionally not used to run the launcher or test
Steam Input; it cannot faithfully reproduce Bazzite's desktop, Steam, or
controller focus behaviour.
