#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "gcm.h"

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

    unsigned char *pt = malloc(filesize);
    size_t read_bytes = fread(pt, 1, filesize, fp);
    (void)read_bytes;
    fclose(fp);

    unsigned char key[16] = {0}; // 128-bit zero key
    unsigned char iv[12] = {0};  // 96-bit zero IV
    unsigned char aad[0] = {};   // No AAD
    unsigned char tag[16];
    unsigned char *ct = malloc(filesize);

    gcm_context ctx;
    gcm_setkey(&ctx, key, 16);

    // ⏱ 타이밍 시작
    clock_t start = clock();
    gcm_crypt_and_tag(&ctx, ENCRYPT, iv, 12, aad, 0, pt, ct, filesize, tag, 16);
    clock_t end = clock();
    // ⏱ 타이밍 종료

    double elapsed_sec = (double)(end - start) / CLOCKS_PER_SEC;
    fprintf(stderr, "Time taken for AES-GCM encryption: %.6f sec\n", elapsed_sec);

    free(pt);
    free(ct);
    return 0;
}
