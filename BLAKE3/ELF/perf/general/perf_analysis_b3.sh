#!/bin/bash
# perf_analysis_b3.sh - BLAKE3 성능 측정 스크립트 (x86, AVX2, RISC-V, RISC-V V-type)

export LC_ALL=C
repeat=100

# 캐시 클리어
echo 3 | sudo tee /proc/sys/vm/drop_caches

# 메모리 제한
ulimit -v $((8 * 1024 * 1024))  # 8GB

# 테스트할 파일 크기 목록 (KB 단위)
sizes=(1 2 4 8 16 32 64 128 256 512 1024 2048 4096 8192 10240)

# 실행 파일들 (SPIKE 포함)
executables=(
  "ulimit -v $((8 * 1024 * 1024)); taskset -c 0-3 ./b3_x86"
  "ulimit -v $((8 * 1024 * 1024)); taskset -c 0-3 ./b3_avx2"
  "taskset -c 0-3 spike --isa=rv64gcv_zve32x -m8192 ./b3_riscv"
  "taskset -c 0-3 spike --isa=rv64gcv_zve32x_vlen=256 -m8192 ./b3_riscv_v"
  "taskset -c 0-3 spike --isa=rv64gcv_zve32x_vlen=512 -m8192 ./b3_riscv_v"
  "taskset -c 0-3 spike --isa=rv64gcv_zve32x_vlen=1024 -m8192 ./b3_riscv_v"
)

# 결과 CSV 저장
output_csv="perf_results_b3.csv"
echo "FileSizeKB,ExecName,VLEN,TaskClock,TaskClock_StdDev,Cycles,Cycles_StdDev,PageFaults,PageFaults_StdDev,CpuClock,CpuClock_StdDev" > "${output_csv}"

for size in "${sizes[@]}"; do
  file="datafile/test_${size}KB.txt"
  if [ ! -f "$file" ]; then
    echo "⚠️ File $file does not exist. Skipping."
    continue
  fi

  echo "🔹 Testing $file (${size}KB)..."

  for exe in "${executables[@]}"; do
    task_times=(); cycles_times=(); pf_times=(); cpu_times=()
    echo "  ➤ Running $exe ..."

    for ((i=1; i<=repeat; i++)); do
      output=$( { /usr/bin/time -p perf stat -e task-clock,cycles,page-faults,cpu-clock -r 1 bash -c "${exe} < ${file}" > /dev/null; } 2>&1 )
      task=$(echo "$output" | grep "task-clock" | awk '{print $1}' | tr -d ',')
      cycles=$(echo "$output" | grep "cycles" | head -n 1 | awk '{print $1}' | tr -d ',')
      pf=$(echo "$output" | grep "page-faults" | awk '{print $1}' | tr -d ',')
      cpu=$(echo "$output" | grep "cpu-clock" | awk '{print $1}' | tr -d ',')

      task=${task:-0}; cycles=${cycles:-0}; pf=${pf:-0}; cpu=${cpu:-0}
      [[ "$task" =~ ^[0-9]+([.][0-9]+)?$ ]] && task_times+=("$task")
      [[ "$cycles" =~ ^[0-9]+([.][0-9]+)?$ ]] && cycles_times+=("$cycles")
      [[ "$pf" =~ ^[0-9]+([.][0-9]+)?$ ]] && pf_times+=("$pf")
      [[ "$cpu" =~ ^[0-9]+([.][0-9]+)?$ ]] && cpu_times+=("$cpu")
    done

    # 평균, 표준편차 함수
    mean_stddev() {
      local -n arr=$1
      local sum=0; local sum_sq=0; local count=${#arr[@]}
      if [ "$count" -eq 0 ]; then echo "0,0"; return; fi
      for value in "${arr[@]}"; do
        sum=$(echo "$sum + $value" | bc)
        sum_sq=$(echo "$sum_sq + ($value * $value)" | bc)
      done
      mean=$(echo "scale=4; $sum / $count" | bc)
      variance=$(echo "scale=4; ($sum_sq / $count) - ($mean * $mean)" | bc)
      stddev=$(echo "scale=4; sqrt($variance)" | bc 2>/dev/null || echo "0")
      echo "$mean,$stddev"
    }

    # VLEN 추출
    if [[ "$exe" == *"vlen="* ]]; then
      vlen=$(echo "$exe" | grep -oP 'vlen=\K[0-9]+')
    else
      vlen="NaN"
    fi

    # 값 계산 및 CSV 저장
    echo "${size},${exe},${vlen},$(mean_stddev task_times),$(mean_stddev cycles_times),$(mean_stddev pf_times),$(mean_stddev cpu_times)" >> "${output_csv}"
  done
done

echo "✅ BLAKE3 성능 결과 저장 완료: ${output_csv}"
