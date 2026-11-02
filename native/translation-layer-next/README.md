# Husk translation-layer-next import

This directory contains verbatim source files imported from:

- Upstream: https://github.com/Leviidev/Husk
- Revision: `89b0f8757da53e4dcef0e8eafdb888b343c638d0`
- License: GPL-2.0-or-later (see each source file's SPDX header).

## Imported subsystems

- Executable memory and JIT arena primitives
- Code-write compatibility
- Dynamic ELF linker/loader interface and implementation
- ARM32 guest translation interface and implementation
- AArch64 instruction-field decoder
- Bionic compatibility interface and initial implementation
- JNI object/runtime interface, implementation and HLE table
- DEX class/member index
- Dalvik/Android framework runtime core and NativeActivity bridge

## Integration status

These files are an upstream integration base, not a claim that Stride can launch APKs yet. They are not currently part of the host CMake parser target. The next engineering work is to close dependencies, reconcile shared structures with Stride's existing parser, add an iOS SDK build target, and add runtime tests. Apple-specific files must be compiled and tested against the actual iOS SDK before runtime claims are made.

The parser and ELF metadata tests remain separate and do not validate APK execution.

## Exclusions

No full Android OS image, Android VM, QEMU guest, or bootable Android system is included.
