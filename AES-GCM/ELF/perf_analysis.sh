#!/bin/bash
# perf_analysis.sh
# 다양한 크기의 랜덤 데이터에 대해 X86, AVX2, RISC-V, RISC-V V-Type 성능 비교

export LC_ALL=C  # 소수점 포맷 고정

# 테스트할 파일 크기 목록 (단위: KB)
sizes=(1 10 100 1024 10240 52428 104857 524288)  # 1KB ~ 500MB

# 실행 파일 목록
executables=(
  "./aes_gcm_x86"
  "./aes_gcm_avx2"
  "./aes_gcm_riscv"
  "./aes_gcm_riscv_v"
)

# 결과 CSV 파일
output_csv="perf_results.csv"
echo "FileSizeKB,ExecName,TaskClock,Cycles,PageFaults,CpuClock" > "${output_csv}"

# 반복 횟수
repeat=10

for size in "${sizes[@]}"; do
  file="datafile/test_${size}KB.txt"
  if [ ! -f "$file" ]; then
    echo "File $file does not exist. Skipping."
    continue
  fi
  echo "Testing file $file (${size} KB = $((size/1024)) MB)..."

  for exe in "${executables[@]}"; do
    sum_task=0
    sum_cycles=0
    sum_pf=0
    sum_cpu=0

    for ((i=1; i<=repeat; i++)); do
      # perf stat 실행하여 성능 데이터 수집
      output=$( { /usr/bin/time -p perf stat -e task-clock,cycles,page-faults,cpu-clock -r 1 ${exe} < "${file}" > /dev/null; } 2>&1 )

      # 이벤트별 값 추출
      task=$(echo "$output" | grep "task-clock" | awk '{print $1}' | tr -d ',')
      cycles=$(echo "$output" | grep "cycles" | head -n 1 | awk '{print $1}' | tr -d ',')
      pf=$(echo "$output" | grep "page-faults" | awk '{print $1}' | tr -d ',')
      cpu=$(echo "$output" | grep "cpu-clock" | awk '{print $1}' | tr -d ',')

      # 빈 값이면 0으로 설정
      task=${task:-0}
      cycles=${cycles:-0}
      pf=${pf:-0}
      cpu=${cpu:-0}

      # 합계 계산
      sum_task=$(echo "$sum_task + $task" | bc)
      sum_cycles=$(echo "$sum_cycles + $cycles" | bc)
      sum_pf=$(echo "$sum_pf + $pf" | bc)
      sum_cpu=$(echo "$sum_cpu + $cpu" | bc)
    done

    # 평균 계산
    avg_task=$(echo "scale=4; $sum_task / $repeat" | bc)
    avg_cycles=$(echo "scale=4; $sum_cycles / $repeat" | bc)
    avg_pf=$(echo "scale=4; $sum_pf / $repeat" | bc)
    avg_cpu=$(echo "scale=4; $sum_cpu / $repeat" | bc)

    # CSV에 기록
    echo "${size},${exe},${avg_task},${avg_cycles},${avg_pf},${avg_cpu}" >> "${output_csv}"
  done
done

echo "Performance measurements saved in ${output_csv}"
