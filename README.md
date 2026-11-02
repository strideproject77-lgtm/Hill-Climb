# Stride

**Stride** is an experimental iOS project exploring a native Android application translation layer.

> **Status: early scaffolding.** This repository currently contains project documentation and setup foundations. It does not yet execute Android APKs.

## Project constraints

- iOS is the host platform.
- Flutter is used for the app UI and project shell.
- The runtime direction is a native translation layer, not a virtual Android device.
- No QEMU, full Android OS image, or Android VM is included.
- Initial native target: 64-bit ARM Android application code (`arm64-v8a`).
- Runtime components will be integrated only after source, dependency, platform and license checks.

## Planned subsystems

- APK / split-package import and inspection
- ELF64 parsing, mapping, relocations and symbol resolution
- Bionic ABI compatibility over Darwin
- JNI and Android framework compatibility
- Graphics, audio, input, storage and networking bridges
- Runtime diagnostics, crash reports and compatibility profiles

These are goals, not claims that the components are already implemented.

## Development

See:
- [Architecture](docs/ARCHITECTURE.md)
- [Licensing](docs/LICENSING.md)
- [Third-party notices](THIRD_PARTY_NOTICES.md)

## Upstream research

Husk: https://github.com/Leviidev/Husk

Stride will selectively adapt compatible Husk translation-layer code. It will preserve upstream copyright and license notices and will not copy QEMU or VM-related components.

## License

Stride's original project code is intended to be distributed under **GPL-2.0-or-later**. See [LICENSE](LICENSE) and [docs/LICENSING.md](docs/LICENSING.md). Third-party components may carry their own licenses.
