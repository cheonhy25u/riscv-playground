#!/bin/bash
# perf_analysis.sh - X86, AVX2, RISC-V, RISC-V V-Type 성능 비교 (100회 반복, SPIKE 최적화 적용, 8GB 메모리 제한)

export LC_ALL=C  # 소수점 포맷 고정

# ✅ 실행 횟수 증가 (100회)
repeat=100

# ✅ 캐시 초기화 (실행 환경 통제)
echo 3 | sudo tee /proc/sys/vm/drop_caches

# ✅ X86에서도 8GB 메모리 제한 적용
ulimit -v $((8 * 1024 * 1024))  # 8GB 제한

# ✅ 테스트할 파일 크기 목록 (단위: KB)
sizes=(1 2 4 8 16 32 64 128 256 512 1024 2048 4096 8192 10240)

# ✅ 실행 파일 목록 (SPIKE 최적화 옵션 + X86에도 동일한 환경 설정)
executables=(
  "ulimit -v $((8 * 1024 * 1024)); taskset -c 0-3 ./aes_gcm_x86"
  "ulimit -v $((8 * 1024 * 1024)); taskset -c 0-3 ./aes_gcm_avx2"
  "taskset -c 0-3 spike --isa=rv64gcv_zve32x_vlen=256 -m8192 --disable-dtb --rbb-port=0 --log-commits=0 ./aes_gcm_riscv"
  "taskset -c 0-3 spike --isa=rv64gcv_zve32x_vlen=256 -m8192 --disable-dtb --rbb-port=0 --log-commits=0 ./aes_gcm_riscv_v"
)

# ✅ 결과 CSV 파일 생성 (표준 편차 추가)
output_csv="perf_results.csv"
echo "FileSizeKB,ExecName,TaskClock,TaskClock_StdDev,Cycles,Cycles_StdDev,PageFaults,PageFaults_StdDev,CpuClock,CpuClock_StdDev" > "${output_csv}"

for size in "${sizes[@]}"; do
  file="datafile/test_${size}KB.txt"
  if [ ! -f "$file" ]; then
    echo "⚠️ File $file does not exist. Skipping."
    continue
  fi
  echo "🔹 Testing file $file (${size} KB = $((size/1024)) MB)..."

  for exe in "${executables[@]}"; do
    task_times=()
    cycles_times=()
    pf_times=()
    cpu_times=()

    echo "  ➤ Running $exe ($repeat runs)..."

    for ((i=1; i<=repeat; i++)); do
      # ✅ perf stat 실행하여 성능 데이터 수집
      output=$( { /usr/bin/time -p perf stat -e task-clock,cycles,page-faults,cpu-clock -r 1 bash -c "${exe} < ${file}" > /dev/null; } 2>&1 )

      # 이벤트별 값 추출 (빈 값이면 0으로 설정)
      task=$(echo "$output" | grep "task-clock" | awk '{print $1}' | tr -d ',')
      cycles=$(echo "$output" | grep "cycles" | head -n 1 | awk '{print $1}' | tr -d ',')
      pf=$(echo "$output" | grep "page-faults" | awk '{print $1}' | tr -d ',')
      cpu=$(echo "$output" | grep "cpu-clock" | awk '{print $1}' | tr -d ',')

      task=${task:-0}
      cycles=${cycles:-0}
      pf=${pf:-0}
      cpu=${cpu:-0}

      # ✅ 숫자인지 확인 후 저장 (bc 오류 방지)
      [[ "$task" =~ ^[0-9]+([.][0-9]+)?$ ]] && task_times+=("$task")
      [[ "$cycles" =~ ^[0-9]+([.][0-9]+)?$ ]] && cycles_times+=("$cycles")
      [[ "$pf" =~ ^[0-9]+([.][0-9]+)?$ ]] && pf_times+=("$pf")
      [[ "$cpu" =~ ^[0-9]+([.][0-9]+)?$ ]] && cpu_times+=("$cpu")
    done

    # ✅ 평균값 및 표준 편차 계산 함수
    mean_stddev() {
      local -n arr=$1  # 참조 변수 사용 (Bash 4 이상 지원)
      local sum=0
      local sum_sq=0
      local count=${#arr[@]}

      if [ "$count" -eq 0 ]; then
        echo "0,0"  # 데이터가 없을 경우 기본값 반환
        return
      fi

      for value in "${arr[@]}"; do
        sum=$(echo "$sum + $value" | bc)
        sum_sq=$(echo "$sum_sq + ($value * $value)" | bc)
      done

      mean=$(echo "scale=4; $sum / $count" | bc)
      variance=$(echo "scale=4; ($sum_sq / $count) - ($mean * $mean)" | bc)
      stddev=$(echo "scale=4; sqrt($variance)" | bc 2>/dev/null || echo "0")

      echo "$mean,$stddev"
    }

    # ✅ 평균 및 표준 편차 계산
    task_mean_stddev=$(mean_stddev task_times)
    cycles_mean_stddev=$(mean_stddev cycles_times)
    pf_mean_stddev=$(mean_stddev pf_times)
    cpu_mean_stddev=$(mean_stddev cpu_times)

    # ✅ CSV에 기록
    echo "${size},${exe},${task_mean_stddev},${cycles_mean_stddev},${pf_mean_stddev},${cpu_mean_stddev}" >> "${output_csv}"
  done
done

echo "✅ Performance measurements saved in ${output_csv}"
