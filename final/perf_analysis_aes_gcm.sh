#!/bin/bash
# AES-GCM 성능 측정: x86, AVX2, RISC-V, RISC-V V-Type

export LC_ALL=C
repeat=100

echo 3 | sudo tee /proc/sys/vm/drop_caches
ulimit -v $((8 * 1024 * 1024))

sizes=(1 2 4 8 16 32 64 128 256 512 1024 2048 4096 8192 10240)

executables=(
  "ulimit -v $((8 * 1024 * 1024)); taskset -c 0-3 ./AES-GCM/ELF/aes_gcm_x86"
  "ulimit -v $((8 * 1024 * 1024)); taskset -c 0-3 ./AES-GCM/ELF/aes_gcm_avx2"
  "taskset -c 0-3 spike --isa=rv64gcv_zve32x_vlen=256 -m8192 --disable-dtb ./AES-GCM/ELF/aes_gcm_riscv"
  "taskset -c 0-3 spike --isa=rv64gcv_zve32x_vlen=256 -m8192 --disable-dtb ./AES-GCM/ELF/aes_gcm_riscv_v"
)

output_csv="perf_results_aes_gcm.csv"
echo "FileSizeKB,ExecName,TaskClock,TaskClock_StdDev,Cycles,Cycles_StdDev,PageFaults,PageFaults_StdDev,CpuClock,CpuClock_StdDev" > "${output_csv}"

for size in "${sizes[@]}"; do
  file="datafile/test_${size}KB.txt"
  if [ ! -f "$file" ]; then
    echo "⚠️ File $file does not exist. Skipping."
    continue
  fi

  echo "🔹 Testing $file (${size} KB)..."

  for exe in "${executables[@]}"; do
    task_times=()
    cycles_times=()
    pf_times=()
    cpu_times=()

    echo "  ➤ Running $exe ($repeat runs)..."

    for ((i=1; i<=repeat; i++)); do
      output=$( { /usr/bin/time -p perf stat -e task-clock,cycles,page-faults,cpu-clock -r 1 bash -c "${exe} < ${file}" > /dev/null; } 2>&1 )

      task=$(echo "$output" | grep "task-clock" | awk '{print $1}' | tr -d ',')
      cycles=$(echo "$output" | grep "cycles" | head -n 1 | awk '{print $1}' | tr -d ',')
      pf=$(echo "$output" | grep "page-faults" | awk '{print $1}' | tr -d ',')
      cpu=$(echo "$output" | grep "cpu-clock" | awk '{print $1}' | tr -d ',')

      task=${task:-0}
      cycles=${cycles:-0}
      pf=${pf:-0}
      cpu=${cpu:-0}

      [[ "$task" =~ ^[0-9]+([.][0-9]+)?$ ]] && task_times+=("$task")
      [[ "$cycles" =~ ^[0-9]+([.][0-9]+)?$ ]] && cycles_times+=("$cycles")
      [[ "$pf" =~ ^[0-9]+([.][0-9]+)?$ ]] && pf_times+=("$pf")
      [[ "$cpu" =~ ^[0-9]+([.][0-9]+)?$ ]] && cpu_times+=("$cpu")
    done

    mean_stddev() {
      local -n arr=$1
      local sum=0 sum_sq=0 count=${#arr[@]}

      if [ "$count" -eq 0 ]; then
        echo "0,0"
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

    task_mean_stddev=$(mean_stddev task_times)
    cycles_mean_stddev=$(mean_stddev cycles_times)
    pf_mean_stddev=$(mean_stddev pf_times)
    cpu_mean_stddev=$(mean_stddev cpu_times)

    echo "${size},${exe},${task_mean_stddev},${cycles_mean_stddev},${pf_mean_stddev},${cpu_mean_stddev}" >> "${output_csv}"
  done
done

echo "✅ Performance results saved to ${output_csv}"
