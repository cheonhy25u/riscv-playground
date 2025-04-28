#include <immintrin.h>
#include "aes.h"

void aes_cipher_avx2(aes_context *ctx, const uchar input[32], uchar output[32]) {
    __m128i key_schedule[15];
    __m128i state[2];
    
    // Load the input data into AVX2 registers (processing 2 blocks at once)
    for (int i = 0; i < 2; i++) {
        state[i] = _mm_loadu_si128((const __m128i*)(input + i * 16));
    }
    
    // Load the AES key schedule
    for (int i = 0; i < ctx->rounds + 1; i++) {
        key_schedule[i] = _mm_loadu_si128((const __m128i*)&ctx->rk[i * 4]);
    }
    
    // Initial round key addition
    for (int i = 0; i < 2; i++) {
        state[i] = _mm_xor_si128(state[i], key_schedule[0]);
    }
    
    // Main AES rounds
    for (int i = 1; i < ctx->rounds; i++) {
        for (int j = 0; j < 2; j++) {
            state[j] = _mm_aesenc_si128(state[j], key_schedule[i]);
        }
    }
    
    // Final AES round
    for (int i = 0; i < 2; i++) {
        state[i] = _mm_aesenclast_si128(state[i], key_schedule[ctx->rounds]);
    }
    
    // Store the encrypted output
    for (int i = 0; i < 2; i++) {
        _mm_storeu_si128((__m128i*)(output + i * 16), state[i]);
    }
}
