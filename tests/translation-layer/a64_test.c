/* SPDX-License-Identifier: GPL-2.0-or-later */
#include <assert.h>
#include <stdint.h>
#include "husk-tl-a64.h"

int main(void) {
    /* ADD X18, X0, X1: Rd is X18 and Rn/Rm are X0/X1. */
    const uint32_t add = 0x8B010012u;
    bool known = false;
    assert(a64_uses_gpr(add, 18, &known) && known);
    assert((a64_gpr_mask(add) & (1u << 18)) != 0);
    uint32_t moved = a64_subst_gpr(add, 18, 19);
    assert((moved & 31u) == 19u);
    assert((moved & ~(31u)) == (add & ~(31u)));

    /* MOVZ X0, #18: immediate bits are not a register field. */
    const uint32_t movz = 0xD2800240u;
    assert(a64_subst_gpr(movz, 18, 19) == movz);
    assert(!a64_uses_gpr(movz, 18, &known) && known);

    /* Unknown encodings are not rewritten. */
    const uint32_t unknown = 0xFFFFFFFFu;
    assert(!a64_gpr_fields(unknown, (uint8_t[5]){0}, &(int){0}));
    assert(a64_subst_gpr(unknown, 18, 19) == unknown);
    return 0;
}
