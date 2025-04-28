#ifdef RISCV_VECTOR
#include <riscv_vector.h>
#include "blake3_impl.h"
#include <string.h>

// 간단화된 벡터화된 압축 함수 예제
// block_data에서 각 해시 인스턴스에 대해 첫 4바이트(32비트)를 로드하고,
// cv0에 대해 XOR 및 덧셈 연산을 수행합니다.
static inline void blake3_compress_in_place_vector(
    vuint32m1_t *cv0, vuint32m1_t *cv1, vuint32m1_t *cv2, vuint32m1_t *cv3,
    vuint32m1_t *cv4, vuint32m1_t *cv5, vuint32m1_t *cv6, vuint32m1_t *cv7,
    const uint8_t *block_data,
    uint8_t block_len, uint64_t counter, uint8_t flags,
    size_t vl) {
  // 예제에서는 각 해시 인스턴스마다 block_data의 첫 4바이트만 로드합니다.
  uint32_t temp[vl];
  for (size_t i = 0; i < vl; i++) {
    // 각 인스턴스의 블록은 BLAKE3_BLOCK_LEN 크기이며,
    // 여기서는 첫 4바이트만 로드 (실제 구현에서는 16개 워드 전부 필요)
    temp[i] = load32(block_data + i * BLAKE3_BLOCK_LEN);
  }
  vuint32m1_t word0 = vle32_v_u32m1(temp, vl, 0);
  // 단순 예제: cv0 = (cv0 XOR word0) + flags
  *cv0 = vxor_vv_u32m1(*cv0, word0, 0);
  // flags를 32비트 값으로 캐스팅하여 벡터 브로드캐스트
  vuint32m1_t v_flags = vmv_v_x_u32m1((uint32_t)flags, vl);
  *cv0 = vadd_vv_u32m1(*cv0, v_flags, 0);
  // 실제 구현에서는 나머지 cv 값과 여러 라운드의 연산이 필요합니다.
}

// 벡터화된 blake3_hash_many 함수
// 한 번에 vsetvl_e32m1()로 결정된 vl(벡터 길이)만큼의 해시 인스턴스를 동시에 처리합니다.
void blake3_hash_many_vector(const uint8_t *const *inputs, size_t num_inputs,
                             size_t blocks, const uint32_t key[8],
                             uint64_t counter, bool increment_counter,
                             uint8_t flags, uint8_t flags_start,
                             uint8_t flags_end, uint8_t *out) {
  while (num_inputs > 0) {
    // 현재 배치에 대해 처리할 인스턴스 수 (vl)를 결정합니다.
    size_t vl = vsetvl_e32m1(num_inputs);

    // 모든 인스턴스의 초기 체이닝 값(cv)을 key로부터 브로드캐스트합니다.
    vuint32m1_t cv0 = vmv_v_x_u32m1(key[0], vl);
    vuint32m1_t cv1 = vmv_v_x_u32m1(key[1], vl);
    vuint32m1_t cv2 = vmv_v_x_u32m1(key[2], vl);
    vuint32m1_t cv3 = vmv_v_x_u32m1(key[3], vl);
    vuint32m1_t cv4 = vmv_v_x_u32m1(key[4], vl);
    vuint32m1_t cv5 = vmv_v_x_u32m1(key[5], vl);
    vuint32m1_t cv6 = vmv_v_x_u32m1(key[6], vl);
    vuint32m1_t cv7 = vmv_v_x_u32m1(key[7], vl);

    // 각 블록에 대해 처리
    for (size_t b = 0; b < blocks; b++) {
      // 배치 내 각 인스턴스의 b번째 블록 데이터를 하나의 버퍼에 모읍니다.
      uint8_t block_batch[vl * BLAKE3_BLOCK_LEN];
      for (size_t i = 0; i < vl; i++) {
        memcpy(&block_batch[i * BLAKE3_BLOCK_LEN],
               inputs[i] + b * BLAKE3_BLOCK_LEN,
               BLAKE3_BLOCK_LEN);
      }
      // 벡터화된 압축 함수 호출
      blake3_compress_in_place_vector(&cv0, &cv1, &cv2, &cv3,
                                      &cv4, &cv5, &cv6, &cv7,
                                      block_batch, (uint8_t)BLAKE3_BLOCK_LEN,
                                      counter, flags, vl);
      if (increment_counter) {
        counter += 1;
      }
    }

    // 벡터 레지스터에 있는 최종 cv 값을 일반 배열로 저장합니다.
    uint32_t out_array0[vl], out_array1[vl], out_array2[vl], out_array3[vl];
    uint32_t out_array4[vl], out_array5[vl], out_array6[vl], out_array7[vl];
    vse32_v_u32m1(out_array0, cv0, vl, 0);
    vse32_v_u32m1(out_array1, cv1, vl, 0);
    vse32_v_u32m1(out_array2, cv2, vl, 0);
    vse32_v_u32m1(out_array3, cv3, vl, 0);
    vse32_v_u32m1(out_array4, cv4, vl, 0);
    vse32_v_u32m1(out_array5, cv5, vl, 0);
    vse32_v_u32m1(out_array6, cv6, vl, 0);
    vse32_v_u32m1(out_array7, cv7, vl, 0);

    // 각 인스턴스당 32바이트(8 워드)의 해시 결과를 out 버퍼에 기록합니다.
    for (size_t i = 0; i < vl; i++) {
      store32(&out[i * BLAKE3_OUT_LEN + 0],  out_array0[i]);
      store32(&out[i * BLAKE3_OUT_LEN + 4],  out_array1[i]);
      store32(&out[i * BLAKE3_OUT_LEN + 8],  out_array2[i]);
      store32(&out[i * BLAKE3_OUT_LEN + 12], out_array3[i]);
      store32(&out[i * BLAKE3_OUT_LEN + 16], out_array4[i]);
      store32(&out[i * BLAKE3_OUT_LEN + 20], out_array5[i]);
      store32(&out[i * BLAKE3_OUT_LEN + 24], out_array6[i]);
      store32(&out[i * BLAKE3_OUT_LEN + 28], out_array7[i]);
    }

    // 다음 배치로 진행: 입력 포인터와 출력 버퍼를 vl만큼 이동합니다.
    inputs += vl;
    num_inputs -= vl;
    out += vl * BLAKE3_OUT_LEN;
  }
}
#endif
