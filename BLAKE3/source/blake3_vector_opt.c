#include "blake3.h"
#include <riscv_vector.h>

#define MAX_VECTOR_SIZE 256 // 벡터 크기 설정

void blake3_compress_riscv_vtype(uint32_t *cv, const uint32_t *block, size_t num_inputs) {
    size_t vl;
    
    while (num_inputs > 0) {
        vl = __riscv_vsetvl_e32m1(num_inputs); // 올바른 vsetvl 함수 사용
        
        vuint32m1_t word0 = __riscv_vle32_v_u32m1(block, vl);
        vuint32m1_t word1 = __riscv_vle32_v_u32m1(block + vl, vl); // 추가 로드
        
        vuint32m1_t cv0 = __riscv_vle32_v_u32m1(cv, vl);
        vuint32m1_t cv1 = __riscv_vle32_v_u32m1(cv + vl, vl);
        
        cv0 = __riscv_vxor_vv_u32m1(cv0, word0, vl);
        cv1 = __riscv_vxor_vv_u32m1(cv1, word1, vl);
        
        cv0 = __riscv_vadd_vv_u32m1(cv0, word0, vl);
        cv1 = __riscv_vadd_vv_u32m1(cv1, word1, vl);
        
        __riscv_vse32_v_u32m1(cv, cv0, vl);
        __riscv_vse32_v_u32m1(cv + vl, cv1, vl);
        
        block += 2 * vl;
        num_inputs -= 2 * vl;
    }
}
