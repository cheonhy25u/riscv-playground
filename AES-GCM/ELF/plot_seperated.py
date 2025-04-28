import pandas as pd
import matplotlib.pyplot as plt

# CSV 불러오기
df = pd.read_csv("perf_results.csv")

# 기본 계산
df["FileSizeMB"] = df["FileSizeKB"] / 1024
df["Throughput_MBps"] = df["FileSizeMB"] / (df["TaskClock"] / 1000)

# 아키텍처 분류
def label_exec(exec_str):
    if "aes_gcm_avx2" in exec_str:
        return "AVX2"
    elif "aes_gcm_x86" in exec_str:
        return "x86"
    elif "riscv_v" in exec_str and "vlen=256" in exec_str:
        return "V-type"
    elif "aes_gcm_riscv" in exec_str and "riscv_v" not in exec_str:
        return "RISC-V"
    else:
        return "Other"

df["ArchLabel"] = df["ExecName"].apply(label_exec)

# === x86 그래프: AVX2 vs x86 ===
x86_df = df[df["ArchLabel"].isin(["x86", "AVX2"])].copy()
x86_grouped = x86_df.groupby(["ArchLabel", "FileSizeMB"]).agg({"Throughput_MBps": "mean"}).reset_index()

plt.figure(figsize=(8, 5))
for arch in ["x86", "AVX2"]:
    subset = x86_grouped[x86_grouped["ArchLabel"] == arch]
    plt.plot(subset["FileSizeMB"], subset["Throughput_MBps"], marker='o', label=arch)
plt.xscale("log", base=2)
plt.xlabel("File Size (MB)")
plt.ylabel("Throughput (MB/s)")
plt.title("AES-GCM Throughput on x86 (Baseline vs AVX2)")
plt.legend()
plt.grid(True, which='both', linestyle='--', linewidth=0.5)
plt.tight_layout()
plt.savefig("aes_gcm_x86_throughput.png", dpi=300)

# === RISC-V 그래프: RISC-V vs V-type ===
rv_df = df[df["ArchLabel"].isin(["RISC-V", "V-type"])].copy()
rv_grouped = rv_df.groupby(["ArchLabel", "FileSizeMB"]).agg({"Throughput_MBps": "mean"}).reset_index()

plt.figure(figsize=(8, 5))
for arch in ["RISC-V", "V-type"]:
    subset = rv_grouped[rv_grouped["ArchLabel"] == arch]
    plt.plot(subset["FileSizeMB"], subset["Throughput_MBps"], marker='o', label=arch)
plt.xscale("log", base=2)
plt.xlabel("File Size (MB)")
plt.ylabel("Throughput (MB/s)")
plt.title("AES-GCM Throughput on RISC-V (Baseline vs V-type)")
plt.legend()
plt.grid(True, which='both', linestyle='--', linewidth=0.5)
plt.tight_layout()
plt.savefig("aes_gcm_riscv_throughput.png", dpi=300)
