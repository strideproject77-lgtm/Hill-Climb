/* SPDX-License-Identifier: GPL-2.0-or-later */
/*
 * Stride's bounded ELF image metadata parser.
 *
 * This is loader preparation only: it validates ELF64/AArch64 program headers
 * and describes PT_LOAD/PT_GNU_RELRO/PT_DYNAMIC ranges. It does not map memory,
 * apply relocations, change page protections, or execute guest code.
 */
#ifndef STRIDE_ELF_IMAGE_H
#define STRIDE_ELF_IMAGE_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define STRIDE_ELF_MAX_LOADS 32

typedef struct stride_elf_segment {
    uint64_t file_offset;
    uint64_t virtual_address;
    uint64_t file_size;
    uint64_t memory_size;
    uint64_t alignment;
    uint32_t flags;
} stride_elf_segment;

typedef struct stride_elf_image {
    uint64_t min_vaddr;
    uint64_t max_vaddr;
    uint64_t entry;
    uint64_t dynamic_vaddr;
    uint64_t dynamic_size;
    stride_elf_segment loads[STRIDE_ELF_MAX_LOADS];
    size_t load_count;
    bool has_relro;
    uint64_t relro_vaddr;
    uint64_t relro_size;
} stride_elf_image;

/* Returns true only for a structurally valid little-endian ELF64 AArch64
 * ET_DYN image. Error is optional and receives a short diagnostic. */
bool stride_elf_image_parse(const uint8_t *bytes, size_t size,
                            stride_elf_image *out,
                            char *error, size_t error_size);

#endif
