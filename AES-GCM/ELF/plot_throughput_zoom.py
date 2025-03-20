import pandas as pd
import matplotlib.pyplot as plt

# CSV 파일 불러오기
df = pd.read_csv("perf_throughput.csv")

# 실행 파일 목록 추출
executables = df["ExecName"].unique()

plt.figure(figsize=(10, 6))

# 각 실행 파일별로 그래프 그리기
for exe in executables:
    sub_df = df[df["ExecName"] == exe]
    plt.plot(sub_df["FileSizeKB"], sub_df["Throughput_MBps"], marker="o", linestyle="-", label=exe)

plt.xscale("log")  # ✅ X축 로그 스케일 적용
plt.yscale("log")  # ✅ Y축 로그 스케일 적용
plt.xlabel("File Size (KB) [Log Scale]")
plt.ylabel("Throughput (MB/s) [Log Scale]")
plt.title("Throughput Comparison (X86, AVX2, RISC-V, RISC-V V-Type) [Log-Log Scale]")
plt.legend()
plt.grid(True, which="both", linestyle="--")  # 로그 스케일에서도 보이도록 보조선 추가

# 그래프 저장
plt.savefig("throughput_comparison_loglog.png")

# 그래프 표시
plt.show()
