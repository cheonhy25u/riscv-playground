#!/bin/bash
# perf_analysis.sh - 성능 비교 (AVX2, RISC-V V-Type 포함, VLEN별 Throughput 분석 용이하도록 수정)

export LC_ALL=C  # 소수점 포맷 고정
repeat=100        # 반복 횟수 (빠른 테스트용으로 줄여둠, 필요 시 100으로 증가)
ulimit -v $((8 * 1024 * 1024))  # 8GB 제한

sizes=(1 2 4 8 16 32 64 128 256 512 1024 2048 4096 8192 10240)

executables=(
  "ulimit -v $((8 * 1024 * 1024)); taskset -c 0-3 ./aes_gcm_x86"
  "ulimit -v $((8 * 1024 * 1024)); taskset -c 0-3 ./aes_gcm_avx2"
  "taskset -c 0-3 spike --isa=rv64gcv_zve32x -m8192 ./aes_gcm_riscv"
  "taskset -c 0-3 spike --isa=rv64gcv_zve32x_vlen=256 -m8192 ./aes_gcm_riscv_v"
  "taskset -c 0-3 spike --isa=rv64gcv_zve32x_vlen=512 -m8192 ./aes_gcm_riscv_v"
  "taskset -c 0-3 spike --isa=rv64gcv_zve32x_vlen=1024 -m8192 ./aes_gcm_riscv_v"
)

output_csv="perf_results.csv"
echo "FileSizeKB,ExecName,VLEN,TaskClock,TaskClock_StdDev,Cycles,Cycles_StdDev,PageFaults,PageFaults_StdDev,CpuClock,CpuClock_StdDev" > "${output_csv}"

for size in "${sizes[@]}"; do
  file="datafile/test_${size}KB.txt"
  [ ! -f "$file" ] && echo "⚠️ File $file does not exist. Skipping." && continue
  echo "🔹 Testing file $file (${size} KB = $((size/1024)) MB)..."

  for exe in "${executables[@]}"; do
    task_times=(); cycles_times=(); pf_times=(); cpu_times=()

    echo "  ➤ Running $exe ($repeat runs)..."

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

    mean_stddev() {
      local -n arr=$1; local sum=0; local sum_sq=0; local count=${#arr[@]}
      [ "$count" -eq 0 ] && echo "0,0" && return
      for value in "${arr[@]}"; do
        sum=$(echo "$sum + $value" | bc)
        sum_sq=$(echo "$sum_sq + ($value * $value)" | bc)
      done
      mean=$(echo "scale=4; $sum / $count" | bc)
      variance=$(echo "scale=4; ($sum_sq / $count) - ($mean * $mean)" | bc)
      stddev=$(echo "scale=4; sqrt($variance)" | bc 2>/dev/null || echo "0")
      echo "$mean,$stddev"
    }

    task_mean_stddev=$(mean_stddev task_times)
    cycles_mean_stddev=$(mean_stddev cycles_times)
    pf_mean_stddev=$(mean_stddev pf_times)
    cpu_mean_stddev=$(mean_stddev cpu_times)

    # VLEN 추출
    if [[ "$exe" == *"vlen="* ]]; then
      vlen=$(echo "$exe" | grep -oP 'vlen=\K[0-9]+')
    else
      vlen="NaN"
    fi

    echo "${size},${exe},${vlen},${task_mean_stddev},${cycles_mean_stddev},${pf_mean_stddev},${cpu_mean_stddev}" >> "${output_csv}"
  done
done

echo "✅ Performance measurements saved in ${output_csv}"
