/* SPDX-License-Identifier: GPL-2.0-or-later */
/* Focused structural tests for Stride's bounded ELF image parser. */
#include "stride-elf-image.h"
#include <elf.h>
#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#define IMAGE_SIZE 120
static void put16(uint8_t *p, uint16_t v) { p[0]=(uint8_t)v; p[1]=(uint8_t)(v>>8); }
static void put32(uint8_t *p, uint32_t v) { for(unsigned i=0;i<4;i++) p[i]=(uint8_t)(v>>(8*i)); }
static void put64(uint8_t *p, uint64_t v) { for(unsigned i=0;i<8;i++) p[i]=(uint8_t)(v>>(8*i)); }
static void make_image(uint8_t b[IMAGE_SIZE]) {
    memset(b,0,IMAGE_SIZE); b[0]=0x7f; b[1]='E'; b[2]='L'; b[3]='F';
    b[4]=ELFCLASS64; b[5]=ELFDATA2LSB; b[6]=EV_CURRENT;
    put16(b+16,ET_DYN); put16(b+18,EM_AARCH64); put64(b+24,0x1010);
    put64(b+32,64); put16(b+52,64); put16(b+54,56); put16(b+56,1);
    uint8_t *p=b+64; put32(p,PT_LOAD); put32(p+4,PF_R|PF_X);
    put64(p+8,0); put64(p+16,0x1000); put64(p+32,IMAGE_SIZE);
    put64(p+40,0x2000); put64(p+48,0x1000);
}
static void expect_reject(uint8_t *b,size_t n) {
    stride_elf_image out; char error[96];
    assert(!stride_elf_image_parse(b,n,&out,error,sizeof(error)));
    assert(error[0]!='\0');
}
int main(void) {
    uint8_t b[IMAGE_SIZE]; stride_elf_image out; char error[96];
    make_image(b);
    assert(stride_elf_image_parse(b,sizeof(b),&out,error,sizeof(error)));
    assert(out.load_count==1 && out.min_vaddr==0x1000 && out.max_vaddr==0x3000);
    assert(out.entry==0x1010 && out.loads[0].file_size==IMAGE_SIZE);
    assert(out.loads[0].memory_size==0x2000);
    make_image(b); b[4]=ELFCLASS32; expect_reject(b,sizeof(b));
    make_image(b); put16(b+18,EM_ARM); expect_reject(b,sizeof(b));
    make_image(b); put64(b+32,UINT64_MAX-8); expect_reject(b,sizeof(b));
    make_image(b); put64(b+64+48,3); expect_reject(b,sizeof(b));
    make_image(b); put32(b+64,PT_NOTE); expect_reject(b,sizeof(b));
    make_image(b); put64(b+64+16,UINT64_MAX-8); put64(b+64+40,32);
    expect_reject(b,sizeof(b)); expect_reject(b,63);
    puts("ELF image parser tests passed."); return 0;
}
