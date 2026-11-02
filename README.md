# Stride

**Stride** is an experimental iOS project exploring a native Android application translation layer.

> **Status: early development.** The repository now contains a Flutter UI shell and imported APK/ELF inspection foundations. It does not yet execute Android APKs.

## Project constraints

- iOS is the host platform.
- Flutter is used for the app UI and project shell.
- The runtime direction is a native translation layer, not a virtual Android device.
- No QEMU, full Android OS image, or Android VM is included.
- Initial native target: 64-bit ARM Android application code (`arm64-v8a`).

## Implemented foundations

- Flutter dashboard shell with honest runtime status.
- APK ZIP entry reader, including ZIP64 and deflated entries.
- ELF64 analysis and 16 KiB page-layout planning.
- APK native-library scanner and JSON compatibility report.
- CMake target and host regression test suite.
- GitHub Actions checks for native parser tests and Flutter analysis.

These foundations are imported/adapted from Husk and remain subject to CI verification. They inspect APKs; they are not an Android execution runtime.

## Planned runtime work

- Native ELF loader and memory mapping
- Bionic ABI and syscall compatibility
- JNI and Android framework support
- Graphics, audio, input, storage and networking bridges
- Runtime diagnostics and crash reports

## Explicit exclusions

- QEMU
- Full Android OS / LineageOS guest
- Android VM or virtual device

## Development

See:
- [Architecture](docs/ARCHITECTURE.md)
- [Licensing](docs/LICENSING.md)
- [Third-party notices](THIRD_PARTY_NOTICES.md)

## Upstream source

Husk: https://github.com/Leviidev/Husk

The imported file list, upstream revision, license and test provenance are recorded in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). Upstream notices are preserved.

## License

Stride's original project code is intended to be distributed under **GPL-2.0-or-later**. See [LICENSE](LICENSE) and [docs/LICENSING.md](docs/LICENSING.md). Third-party components may carry their own licenses.
