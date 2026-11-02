#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-or-later
# Host-side tests for APK parsing, ELF analysis and compatibility reports.
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT=$(CDPATH= cd -- "$HERE/../.." && pwd)
SRC="$ROOT/native/translation-layer"
OUT="${OUT:-$(mktemp -d)}"
mkdir -p "$OUT"
CFLAGS="-std=gnu11 -O2 -g -Wall -Wextra -Werror -I$SRC"

echo "== ELF page planner"
cc $CFLAGS -o "$OUT/plan_test" "$HERE/plan_test.c" "$SRC/husk-tl-elf.c"
"$OUT/plan_test"

echo "== ELF image metadata parser tests"
cc $CFLAGS -o "$OUT/elf_image_test" "$HERE/elf_image_test.c" "$SRC/stride-elf-image.c"
"$OUT/elf_image_test"

echo "== APK and ELF scanner"
cc $CFLAGS -fsanitize=address,undefined -o "$OUT/scan_cli" "$HERE/scan_cli.c" \
  "$SRC/husk-tl-json.c" "$SRC/husk-tl-zip.c" "$SRC/husk-tl-elf.c" \
  "$SRC/husk-tl-scan.c" -lz -lpthread
python3 "$HERE/test_scan.py" "$OUT" "$OUT/scan_cli"
echo "Stride translation-layer parser tests passed."
