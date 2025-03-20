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

plt.xlabel("File Size (KB)")
plt.ylabel("Throughput (MB/s)")
plt.title("Throughput Comparison (X86, AVX2, RISC-V, RISC-V V-Type)")
plt.legend()
plt.grid(True)

# 그래프 저장 (옵션)
plt.savefig("throughput_comparison.png")

# 그래프 표시
plt.show()
