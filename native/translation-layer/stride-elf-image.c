/* SPDX-License-Identifier: GPL-2.0-or-later */
#include "stride-elf-image.h"
#include <elf.h>
#include <stdio.h>
#include <string.h>

static uint16_t rd16(const uint8_t *p) { return (uint16_t)p[0] | (uint16_t)p[1] << 8; }
static uint32_t rd32(const uint8_t *p) { return (uint32_t)p[0] | (uint32_t)p[1] << 8 | (uint32_t)p[2] << 16 | (uint32_t)p[3] << 24; }
static uint64_t rd64(const uint8_t *p) { return (uint64_t)rd32(p) | (uint64_t)rd32(p + 4) << 32; }
static bool range_ok(size_t n, uint64_t o, uint64_t z) { return o <= n && z <= (uint64_t)n - o; }
static bool add_ok(uint64_t a, uint64_t b, uint64_t *v) { if (b > UINT64_MAX - a) return false; *v = a + b; return true; }
static bool fail(char *e, size_t n, const char *s) { if (e && n) snprintf(e, n, "%s", s); return false; }

bool stride_elf_image_parse(const uint8_t *b, size_t n, stride_elf_image *out, char *error, size_t error_size)
{
    if (error && error_size) error[0] = 0;
    if (!b || !out) return fail(error, error_size, "null input");
    memset(out, 0, sizeof(*out));
    if (n < 64 || b[0] != 0x7f || b[1] != 'E' || b[2] != 'L' || b[3] != 'F')
        return fail(error, error_size, "not an ELF64 image");
    if (b[4] != ELFCLASS64 || b[5] != ELFDATA2LSB || b[6] != EV_CURRENT)
        return fail(error, error_size, "unsupported ELF encoding");
    if (rd16(b + 16) != ET_DYN || rd16(b + 18) != EM_AARCH64)
        return fail(error, error_size, "not an AArch64 shared object");
    if (rd16(b + 52) != 64 || rd16(b + 54) != 56)
        return fail(error, error_size, "unexpected ELF header sizes");

    uint64_t phoff = rd64(b + 32);
    uint16_t phnum = rd16(b + 56);
    if (!phnum || phnum > 128 || !range_ok(n, phoff, (uint64_t)phnum * 56))
        return fail(error, error_size, "invalid program header table");

    out->min_vaddr = UINT64_MAX;
    for (uint16_t i = 0; i < phnum; i++) {
        const uint8_t *p = b + (size_t)phoff + (size_t)i * 56;
        uint32_t type = rd32(p), flags = rd32(p + 4);
        uint64_t off = rd64(p + 8), va = rd64(p + 16);
        uint64_t fs = rd64(p + 32), ms = rd64(p + 40), al = rd64(p + 48), end;
        if (type == PT_LOAD) {
            if (out->load_count == STRIDE_ELF_MAX_LOADS) return fail(error, error_size, "too many load segments");
            if (fs > ms || !range_ok(n, off, fs) || !add_ok(va, ms, &end))
                return fail(error, error_size, "invalid load segment range");
            if (al > 1 && ((al & (al - 1)) || va % al != off % al))
                return fail(error, error_size, "invalid load segment alignment");
            stride_elf_segment *s = &out->loads[out->load_count++];
            s->file_offset = off; s->virtual_address = va; s->file_size = fs;
            s->memory_size = ms; s->alignment = al; s->flags = flags;
            if (va < out->min_vaddr) out->min_vaddr = va;
            if (end > out->max_vaddr) out->max_vaddr = end;
        } else if (type == PT_GNU_RELRO) {
            if (!add_ok(va, ms, &end)) return fail(error, error_size, "invalid RELRO range");
            out->has_relro = true; out->relro_vaddr = va; out->relro_size = ms;
        } else if (type == PT_DYNAMIC) {
            if (!range_ok(n, off, fs)) return fail(error, error_size, "invalid dynamic segment");
            out->dynamic_vaddr = va; out->dynamic_size = fs;
        }
    }
    if (!out->load_count) return fail(error, error_size, "image has no PT_LOAD segments");
    out->entry = rd64(b + 24);
    return true;
}
