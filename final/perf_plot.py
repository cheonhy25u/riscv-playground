import pandas as pd
import matplotlib.pyplot as plt

# 파일 경로
aes_csv = "perf_results.csv"
blake_csv = "perf_results_b3.csv"

# Throughput 계산 함수
def compute_throughput(df):
    df = df.copy()
    df["Throughput_MBps"] = (df["FileSizeKB"] / 1024) / df["CpuClock"]
    return df

# 그래프 그리기 함수
def plot_throughput(df, title, output_name):
    plt.figure()
    for exec_name in df["ExecName"].unique():
        subset = df[df["ExecName"] == exec_name]
        label = exec_name.split("/")[-1] if "/" in exec_name else exec_name
        plt.plot(subset["FileSizeKB"], subset["Throughput_MBps"], marker='o', label=label)
    
    plt.xlabel("File Size (KB)")
    plt.ylabel("Throughput (MB/s)")
    plt.title(title)
    plt.legend()
    plt.grid(True)
    plt.savefig(output_name)
    print(f"✅ Saved: {output_name}")
    plt.close()

# CSV 불러오기 및 처리
aes_df = compute_throughput(pd.read_csv(aes_csv))
blake_df = compute_throughput(pd.read_csv(blake_csv))

# Throughput 그래프 생성
plot_throughput(aes_df, "AES-GCM Throughput", "aes_gcm_throughput.png")
plot_throughput(blake_df, "BLAKE3 Throughput", "blake3_throughput.png")
