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
3. **Package inspection** — APK, XAPK, APKS and APKM container inspection; manifest and ABI metadata.
4. **Native loader** — ELF64 validation, 16 KiB page planning, memory layout, relocations and symbol lookup.
5. **Android compatibility** — Bionic ABI shims, Linux-to-Darwin syscall adaptation, JNI and selected Android framework APIs.
6. **Platform services** — graphics, audio, input, filesystem, networking and lifecycle.
7. **Diagnostics** — structured logs, missing-symbol reports, crash capture and per-app compatibility reports.

## Runtime scope

The first target is arm64 Android native code. 32-bit ARM binaries are out of scope for native execution on modern iOS hardware. Java/Dex support requires a separately reviewed runtime integration; it is not implied by APK parsing.

## Integration policy

- Inspect each upstream source file and its build dependencies before copying.
- Keep upstream SPDX and copyright headers.
- Record source URL, revision, modifications and license in `THIRD_PARTY_NOTICES.md`.
- Do not import QEMU, guest boot scripts, Android system images or VM-only code.
- Do not label a subsystem functional until it builds and has a reproducible test.

## Milestones

- M0: repository, license records, Flutter shell and CI checks.
- M1: APK package inspection and robust parser tests.
- M2: ELF64 analysis and 16 KiB layout tests.
- M3: iOS memory/JIT feasibility checks on supported devices.
- M4: first native library load and relocation test.
- M5: minimal Bionic/JNI compatibility.
- M6: first simple app surface and platform service bridges.
- M7: broader game compatibility and device testing.

All milestones after M0 remain unimplemented until verified.
