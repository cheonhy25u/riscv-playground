import pandas as pd
import matplotlib.pyplot as plt

# CSV 파일 불러오기
df = pd.read_csv("perf_results.csv")

# 지표 계산 함수 정의
def add_metrics(df):
    df = df.copy()
    df["Throughput_MBps"] = (df["FileSizeKB"] / 1024) / df["TaskClock"]
    df["CPU_Cycles_per_KB"] = df["Cycles"] / df["FileSizeKB"]
    df["TaskClock_per_KB"] = df["TaskClock"] / df["FileSizeKB"]
    df["Cycles_per_Second"] = df["Cycles"] / df["CpuClock"]
    return df

aes_df = add_metrics(df)

# 그래프 함수
def plot_metric(df, metric, keyword_list, title, ylabel, output):
    plt.figure()
    for keyword in keyword_list:
        subset = df[df["ExecName"].str.contains(keyword)]
        for execname in subset["ExecName"].unique():
            exec_df = subset[subset["ExecName"] == execname]
            label = execname.split("/")[-1]
            plt.plot(exec_df["FileSizeKB"], exec_df[metric], marker='o', label=label)
    plt.xlabel("File Size (KB)")
    plt.ylabel(ylabel)
    plt.title(title)
    plt.grid(True)
    plt.legend()
    plt.savefig(output)
    plt.close()

# 지표별 그래프 출력
metrics = [
    ("Throughput_MBps", "Throughput (MB/s)"),
    ("CPU_Cycles_per_KB", "CPU Cycles per KB"),
    ("TaskClock_per_KB", "Task Clock per KB (s)"),
    ("Cycles_per_Second", "Cycles per Second"),
]

target_sets = [
    ("AES-GCM: x86 vs AVX2", aes_df, ["aes_gcm_x86", "aes_gcm_avx2"], "aes_gcm_x86_vs_avx2"),
    ("AES-GCM: RISC-V vs V-Type", aes_df, ["aes_gcm_riscv$", "aes_gcm_riscv_v"], "aes_gcm_riscv_vs_vtype"),
]

for metric, ylabel in metrics:
    for title, df, keywords, basename in target_sets:
        plot_metric(df, metric, keywords, f"{title} - {metric}", ylabel, f"{basename}_{metric}.png")
