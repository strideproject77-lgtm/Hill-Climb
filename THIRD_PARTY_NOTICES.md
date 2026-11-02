# Third-party notices

This file tracks upstream code and dependencies incorporated into Stride. Each imported file retains its upstream SPDX and copyright notices.

## Husk translation-layer parser

- Project: https://github.com/Leviidev/Husk
- Upstream revision: `89b0f8757da53e4dcef0e8eafdb888b343c638d0`
- Upstream license for these files: GPL-2.0-or-later (confirmed by their SPDX headers).
- Stride destination: `native/translation-layer/`
- Imported files, unchanged:
  - `husk-tl.h`
  - `husk-tl-internal.h`
  - `husk-tl-json.c`
  - `husk-tl-zip.c`
  - `husk-tl-elf.c`
  - `husk-tl-scan.c`
- Purpose: APK ZIP entry reading, ELF64 analysis, 16 KiB page-layout planning, relocation inspection and compatibility reporting.
- Changes made to imported source files: none in the initial import.
- Stride-authored integration: `native/translation-layer/CMakeLists.txt`, test driver and host test runner.
- Excluded: QEMU, guest OS, Android system image, VM boot code and QEMU-dependent device-check test path.

## Upstream regression tests

The following test sources and fixtures were also copied from the same Husk revision and retain their SPDX headers:
- `tests/translation-layer/plan_test.c`
- `tests/translation-layer/test_scan.py`
- `tests/translation-layer/fixtures/empty.c`
- `tests/translation-layer/fixtures/plain.c`
- `tests/translation-layer/fixtures/syscall.c`

Stride's `scan_cli.c` and `run.sh` are adapted for parser-only tests and omit the QEMU-user device-check stage.

## Dependency register

- zlib: used by the APK ZIP reader; system-provided at build time. License: zlib license. No zlib source is vendored here.
- CMake and the C compiler are build tools, not vendored runtime code.
- Flutter SDK is used for the UI shell and is not vendored.

Add each further dependency here before integrating or distributing it, including exact version, license, source URL and required notices.

## Husk translation-layer-next runtime import

- Project: https://github.com/Leviidev/Husk
- Exact upstream revision: `89b0f8757da53e4dcef0e8eafdb888b343c638d0`
- Upstream source directory: `src/translation-layer-next/`
- License: GPL-2.0-or-later, retained per-file through upstream SPDX headers.
- Stride destination: `native/translation-layer-next/`
- Imported verbatim in this batch:
  - `husk-jit-arena.c`, `husk-jit-arena.h`
  - `husk-tl-xmem.c`, `husk-tl-xmem.h`
  - `husk-tl-codewrite.c`, `husk-tl-codewrite.h`
  - `husk-tl-ld.c`, `husk-tl-ld.h`
  - `husk-tl-arm32.c`, `husk-tl-arm32.h`
  - `husk-tl-a64.c`, `husk-tl-a64.h`
  - `husk-tl-bionic.c`, `husk-tl-bionic.h`, `husk-tl-bionic-str.c`
  - `husk-tl-jni.c`, `husk-tl-jni.h`, `husk-tl-jni-internal.h`, `husk-tl-jni-hle.c`
  - `husk-tl-dexindex.c`, `husk-tl-dexindex.h`
  - `husk-tl-dvm.c`, `husk-tl-dvm.h`, `husk-tl-dvm-android.c`, `husk-tl-dvm-internal.h`
  - `husk-tl-nativeactivity.c`, `husk-tl-nativeactivity.h`
- Import status: source is staged as an upstream reference/integration base. It is not yet wired into Stride's CMake target or iOS app build, and it has not yet been validated as a complete runnable runtime. The loader and platform-specific modules require dependency closure, iOS SDK compilation, and integration tests before they can be marked implemented.
- No full Android OS image, Android VM, or QEMU guest was imported.
