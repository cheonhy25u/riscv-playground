#!/bin/bash
# perf_analysis_throughput.sh - X86, AVX2, RISC-V V-Type의 Throughput 비교 (MB/s 단위)

export LC_ALL=C  # 소수점 포맷 고정

repeat=100
echo 3 | sudo tee /proc/sys/vm/drop_caches
ulimit -v $((8 * 1024 * 1024))  # 8GB 제한

sizes=(1 2 4 8 16 32 64 128 256 512 1024 2048 4096 8192 10240)

executables=(
  "ulimit -v $((8 * 1024 * 1024)); taskset -c 0-3 ./aes_gcm_x86"
  "ulimit -v $((8 * 1024 * 1024)); taskset -c 0-3 ./aes_gcm_avx2"
  "taskset -c 0-3 spike --isa=rv64gcv_zve32x_vlen=256 -m8192 ./aes_gcm_riscv"
  "taskset -c 0-3 spike --isa=rv64gcv_zve32x_vlen=256 -m8192 ./aes_gcm_riscv_v"
)

output_csv="perf_throughput.csv"
echo "FileSizeKB,ExecName,TaskClock,Throughput_MBps" > "${output_csv}"

for size in "${sizes[@]}"; do
  file="datafile/test_${size}KB.txt"
  if [ ! -f "$file" ]; then
    echo "⚠️ File $file does not exist. Skipping."
    continue
  fi
  echo "🔹 Testing file $file (${size} KB)..."

  for exe in "${executables[@]}"; do
    task_times=()
    
    echo "  ➤ Running $exe ($repeat runs)..."

    for ((i=1; i<=repeat; i++)); do
      output=$( { /usr/bin/time -p perf stat -e task-clock -r 1 bash -c "${exe} < ${file}" > /dev/null; } 2>&1 )
      task=$(echo "$output" | grep "task-clock" | awk '{print $1}' | tr -d ',')
      task=${task:-0}
      [[ "$task" =~ ^[0-9]+([.][0-9]+)?$ ]] && task_times+=("$task")
    done

    mean_task=0
    count=${#task_times[@]}
    if [ "$count" -gt 0 ]; then
      sum=0
      for value in "${task_times[@]}"; do
        sum=$(echo "$sum + $value" | bc)
      done
      mean_task=$(echo "scale=4; $sum / $count" | bc)
    fi

    # ✅ Throughput 계산: MB/s 단위
    throughput=$(echo "scale=4; (${size} / 1024) / (${mean_task} / 1000)" | bc)
    echo "${size},${exe},${mean_task},${throughput}" >> "${output_csv}"
  done
done

echo "✅ Performance measurements saved in ${output_csv}"
