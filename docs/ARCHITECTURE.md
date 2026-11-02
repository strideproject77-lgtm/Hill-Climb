# Stride architecture

## Product boundary

Stride is an iOS host application with a native Android compatibility runtime. It is not an Android virtual machine.

### Explicit exclusions

- QEMU and CPU emulation
- Full Android OS / LineageOS guest
- Android VM, virtual device, or Android launcher

### Application layers

1. **Flutter app shell** — navigation, library, import flow, settings and diagnostics UI.
2. **iOS host bridge** — Swift / Objective-C++ boundary between Flutter and native runtime services.
3. **Package inspection** — APK ZIP reader, split-package inspection and manifest/ABI metadata.
4. **Native analysis** — ELF64 validation, 16 KiB page planning, relocation inspection and compatibility reports.
5. **Native loader (future)** — memory mapping, relocations and symbol resolution for actual execution.
6. **Android compatibility (future)** — Bionic ABI shims, Linux-to-Darwin syscall adaptation, JNI and selected Android framework APIs.
7. **Platform services (future)** — graphics, audio, input, filesystem, networking and lifecycle.
8. **Diagnostics** — structured logs, missing-symbol reports, crash capture and per-app compatibility reports.

## Current implementation

The initial Husk parser foundation has been imported under `native/translation-layer/`:
- ZIP/APK entry reader
- ELF64 parser and 16 KiB page planner
- APK native-library scanner and JSON reporting

A CMake target and host regression tests have been added. The GitHub Actions workflow is configured to run parser tests and Flutter analysis; results must be checked after the workflow executes.

**These components inspect APKs and native libraries. They do not load or execute Android apps.**

## Runtime scope

The first target is arm64 Android native code. 32-bit ARM binaries are out of scope for native execution on modern iOS hardware. Java/Dex support requires a separately reviewed runtime integration; it is not implied by APK parsing.

## Integration policy

- Inspect each upstream source file and its build dependencies before copying.
- Keep upstream SPDX and copyright headers.
- Record source URL, revision, modifications and license in `THIRD_PARTY_NOTICES.md`.
- Do not import QEMU, guest boot scripts, Android system images or VM-only code.
- Do not label a subsystem functional until it builds and has a reproducible test.

## Milestones

- M0: repository, license records, Flutter shell and CI foundations — **added; CI not yet verified**.
- M1: APK ZIP reader, ELF64 analysis, page planner and scanner — **source imported; tests not yet verified**.
- M2: iOS memory/JIT feasibility checks on supported devices — not started.
- M3: first native library load and relocation test — not started.
- M4: minimal Bionic/JNI compatibility — not started.
- M5: first simple app surface and platform service bridges — not started.
- M6: broader game compatibility and device testing — not started.

All milestones after M1 remain unimplemented until verified.
