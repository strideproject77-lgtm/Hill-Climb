/* SPDX-License-Identifier: GPL-2.0-or-later */
/* Stride test driver for the APK scanner and ZIP entry reader. */
#include "husk-tl.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char **argv)
{
    if (argc >= 2 && !strcmp(argv[1], "scan")) {
        char *json = husk_tl_scan((const char *const *)(argv + 2), argc - 2);
        puts(json ? json : "null");
        husk_tl_free(json);
        return json ? 0 : 1;
    }
    if (argc == 5 && !strcmp(argv[1], "entry")) {
        size_t len = 0;
        void *data = husk_tl_read_entry(argv[2], argv[3], strtoull(argv[4], NULL, 10), &len);
        if (!data) return 1;
        fwrite(data, 1, len, stdout);
        husk_tl_free(data);
        return 0;
    }
    fprintf(stderr, "usage: scan_cli scan APK... | entry APK NAME LIMIT\n");
    return 2;
}
