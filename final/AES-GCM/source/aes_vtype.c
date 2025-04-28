#include <riscv_vector.h>
#include "aes.h"

void aes_cipher_vtype(aes_context *ctx, const uchar input[32], uchar output[32]) {
    size_t vl = __riscv_vsetvlmax_e64m1(); // 올바른 벡터 길이 설정
    vuint64m1_t state0, state1, key0, key1;

    // Load input data into vector registers (데이터 타입 변환 필요)
    state0 = __riscv_vle64_v_u64m1((const uint64_t*) (input), vl);
    state1 = __riscv_vle64_v_u64m1((const uint64_t*) (input + 8), vl);

    // Load AES key schedule (데이터 타입 변환 필요)
    key0 = __riscv_vle64_v_u64m1((const uint64_t*) &(ctx->rk[0]), vl);
    key1 = __riscv_vle64_v_u64m1((const uint64_t*) &(ctx->rk[2]), vl);

    // Initial round key addition
    state0 = __riscv_vxor_vv_u64m1(state0, key0, vl);
    state1 = __riscv_vxor_vv_u64m1(state1, key1, vl);

    // Main AES rounds (RVV에는 AES 전용 명령어가 없으므로 소프트웨어 처리)
    for (int i = 1; i < ctx->rounds; i++) {
        key0 = __riscv_vle64_v_u64m1((const uint64_t*) &(ctx->rk[i * 2]), vl);
        key1 = __riscv_vle64_v_u64m1((const uint64_t*) &(ctx->rk[i * 2 + 2]), vl);

        state0 = __riscv_vxor_vv_u64m1(state0, key0, vl); // AES 라운드 연산 (소프트웨어 처리)
        state1 = __riscv_vxor_vv_u64m1(state1, key1, vl);
    }

    // Final AES round
    key0 = __riscv_vle64_v_u64m1((const uint64_t*) &(ctx->rk[ctx->rounds * 2]), vl);
    key1 = __riscv_vle64_v_u64m1((const uint64_t*) &(ctx->rk[ctx->rounds * 2 + 2]), vl);

    state0 = __riscv_vxor_vv_u64m1(state0, key0, vl); // 마지막 XOR (AES 최종 라운드)
    state1 = __riscv_vxor_vv_u64m1(state1, key1, vl);

    // Store the encrypted output (출력 버퍼를 uint64_t*로 변환 필요)
    __riscv_vse64_v_u64m1((uint64_t*) (output), state0, vl);
    __riscv_vse64_v_u64m1((uint64_t*) (output + 8), state1, vl);
}
