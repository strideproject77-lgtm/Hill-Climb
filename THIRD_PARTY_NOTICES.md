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
