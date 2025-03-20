import pandas as pd
import matplotlib.pyplot as plt

# ✅ CSV 파일 로드
df = pd.read_csv("perf_results.csv")
df["FileSizeMB"] = df["FileSizeKB"] / 1024.0

# ✅ 성능 지표 선택
metrics = {
    "TaskClock": "Task Clock (msec)",
    "Cycles": "Cycles",
    "PageFaults": "Page Faults",
    "CpuClock": "CPU Clock (msec)"
}

# ✅ 실행 파일별 필터링
df_x86 = df[df["ExecName"] == "./aes_gcm_x86"]
df_x86_avx2 = df[df["ExecName"] == "./aes_gcm_avx2"]
df_riscv_normal = df[(df["ExecName"] == "spike -m8192 --isa=rv64gcv --disable-dtb --rbb-port=0 --log-commits=0 ./aes_gcm_riscv")]
df_riscv_vtype = df[df["ExecName"].str.contains("riscv_v") & (df["VLEN"] != "N/A")]

# ✅ 최적 VLEN 선택 (TaskClock이 가장 낮은 VLEN을 선택)
if not df_riscv_vtype.empty:
    best_vlen = df_riscv_vtype.groupby("VLEN")["TaskClock"].mean().idxmin()
    df_riscv_vtype_best = df_riscv_vtype[df_riscv_vtype["VLEN"] == best_vlen]
else:
    best_vlen = "N/A"
    df_riscv_vtype_best = pd.DataFrame()

for metric, ylabel in metrics.items():
    plt.figure(figsize=(8, 6))

    # ✅ x86 성능 그래프
    plt.plot(df_x86["FileSizeMB"], df_x86[metric], marker="o", linestyle="-", label="x86", color="blue")

    # ✅ x86 AVX2 성능 그래프
    plt.plot(df_x86_avx2["FileSizeMB"], df_x86_avx2[metric], marker="s", linestyle="--", label="x86 AVX2", color="orange")

    # ✅ 일반 RISC-V 성능 그래프
    plt.plot(df_riscv_normal["FileSizeMB"], df_riscv_normal[metric], marker="^", linestyle="-", label="RISC-V", color="red")

    # ✅ 최적 VLEN을 사용한 RISC-V V-Type 그래프
    plt.plot(df_riscv_vtype_best["FileSizeMB"], df_riscv_vtype_best[metric], marker="d", linestyle=":", label=f"RISC-V VType (VLEN={best_vlen})", color="green")

    # ✅ 그래프 설정
    plt.xlabel("Input File Size (MB)")
    plt.ylabel(ylabel)
    plt.title(f"{ylabel} vs. Input File Size (MB)")
    plt.legend()
    plt.grid(True, linestyle="--", linewidth=0.5)
    plt.xscale("log")
    plt.savefig(f"{metric}_vs_FileSizeMB.png", dpi=300)
    plt.close()

print(f"✅ 최적 VLEN: {best_vlen}")
print("✅ 그래프 생성 완료! *_vs_FileSizeMB.png 파일 확인")
