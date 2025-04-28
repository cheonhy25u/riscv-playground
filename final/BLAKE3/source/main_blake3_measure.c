#include "blake3.h"
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <inputfile>\n", argv[0]);
        return 1;
    }

    FILE *fp = fopen(argv[1], "rb");
    if (!fp) {
        perror("fopen");
        return 1;
    }

    fseek(fp, 0, SEEK_END);
    size_t filesize = ftell(fp);
    fseek(fp, 0, SEEK_SET);

    uint8_t *buf = malloc(filesize);
    size_t read_bytes = fread(buf, 1, filesize, fp);
    (void)read_bytes;

    fclose(fp);

    blake3_hasher hasher;
    blake3_hasher_init(&hasher);

    // ⏱ 측정 시작
    clock_t start = clock();
    blake3_hasher_update(&hasher, buf, filesize);
    uint8_t output[BLAKE3_OUT_LEN];
    blake3_hasher_finalize(&hasher, output, BLAKE3_OUT_LEN);
    clock_t end = clock();
    // ⏱ 측정 종료

    double elapsed = (double)(end - start) / CLOCKS_PER_SEC;
    fprintf(stderr, "Time taken for BLAKE3 hashing: %.6f sec\n", elapsed);

    free(buf);
    return 0;
}
