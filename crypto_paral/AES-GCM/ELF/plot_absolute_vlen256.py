import pandas as pd
import matplotlib.pyplot as plt

# CSV 불러오기
df = pd.read_csv("perf_results.csv")

# 정확한 실행 환경 구분 함수
def label_exec(exec_str):
    if "avx2" in exec_str:
        return "AVX2"
    elif "x86" in exec_str:
        return "x86"
    elif "vlen=256" in exec_str:
        return "V-type"
    elif "riscv" in exec_str and "riscv_v" not in exec_str:
        return "RISC-V"
    else:
        return "Unknown"

df["ArchLabel"] = df["ExecName"].apply(label_exec)

# Throughput 계산
df["FileSizeMB"] = df["FileSizeKB"] / 1024
df["Throughput_MBps"] = df["FileSizeMB"] / (df["TaskClock"] / 1000)

# 그래프 그리기
plt.figure(figsize=(10, 6))
for arch in ["x86", "AVX2", "RISC-V", "V-type"]:
    subset = df[df["ArchLabel"] == arch]
    if not subset.empty:
        plt.plot(subset["FileSizeMB"], subset["Throughput_MBps"], marker='o', label=arch)

plt.title("Throughput vs File Size (V-type: VLEN=256)", fontsize=14)
plt.xlabel("File Size (MB)", fontsize=12)
plt.ylabel("Throughput (MB/s)", fontsize=12)
plt.legend(title="Architecture")
plt.grid(True)
plt.tight_layout()

# 저장
plt.savefig("throughput_vlen256.png", dpi=300)
print("✅ 그래프 저장 완료: throughput_vlen256.png")
