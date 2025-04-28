import pandas as pd
import matplotlib.pyplot as plt

# CSV 파일 불러오기
df = pd.read_csv("perf_results_b3_embeded.csv")  # 파일 경로 필요 시 수정

# 아키텍처 라벨링 함수
def label_exec(exec_str):
    if "b3_avx2" in exec_str:
        return "AVX2"
    elif "b3_x86" in exec_str:
        return "x86"
    elif "b3_riscv_v" in exec_str and "vlen=256" in exec_str:
        return "V-type"
    elif "b3_riscv" in exec_str and "riscv_v" not in exec_str:
        return "RISC-V"
    else:
        return "Unknown"

# 라벨 및 Throughput 계산
df["ArchLabel"] = df["ExecName"].apply(label_exec)
df["FileSizeMB"] = df["FileSizeKB"] / 1024
df["Throughput_MBps"] = df["FileSizeMB"] / (df["TaskClock"] / 1000)

# 🔹 x86 그래프 그리기
x86_archs = ["x86", "AVX2"]
plt.figure(figsize=(8, 5))
for arch in x86_archs:
    subset = df[df["ArchLabel"] == arch]
    if not subset.empty:
        plt.plot(subset["FileSizeMB"], subset["Throughput_MBps"], marker='o', label=arch)
plt.title("BLAKE3 Throughput on x86 (Baseline vs AVX2)")
plt.xlabel("File Size (MB)")
plt.ylabel("Throughput (MB/s)")
plt.legend()
plt.grid(True)
plt.tight_layout()
plt.savefig("blake3_throughput_x86.png", dpi=300)

# 🔹 RISC-V 그래프 그리기
riscv_archs = ["RISC-V", "V-type"]
plt.figure(figsize=(8, 5))
for arch in riscv_archs:
    subset = df[df["ArchLabel"] == arch]
    if not subset.empty:
        plt.plot(subset["FileSizeMB"], subset["Throughput_MBps"], marker='o', label=arch)
plt.title("BLAKE3 Throughput on RISC-V (Baseline vs V-type)")
plt.xlabel("File Size (MB)")
plt.ylabel("Throughput (MB/s)")
plt.legend()
plt.grid(True)
plt.tight_layout()
plt.savefig("blake3_throughput_riscv.png", dpi=300)
