import pandas as pd
import matplotlib.pyplot as plt

df = pd.read_csv("perf_results.csv")
df["FileSizeMB"] = df["FileSizeKB"] / 1024.0

metrics = {
    "TaskClock": "Task Clock (msec)",
    "Cycles": "Cycles",
    "PageFaults": "Page Faults",
    "CpuClock": "CPU Clock (msec)"
}
executables = df["ExecName"].unique()

for metric, ylabel in metrics.items():
    plt.figure(figsize=(8,6))
    for exe in executables:
        sub_df = df[df["ExecName"] == exe].sort_values("FileSizeMB")
        plt.plot(sub_df["FileSizeMB"], sub_df[metric], marker="o", label=exe)

    plt.xlabel("Input File Size (MB)")
    plt.ylabel(ylabel)
    plt.title(f"{ylabel} vs. Input File Size (MB)")
    plt.legend()
    plt.grid(True)
    plt.xscale("log")  # 로그 스케일로 가독성 향상
    plt.savefig(f"{metric}_vs_FileSizeMB.png")
    plt.close()

print("Graphs saved as *_vs_FileSizeMB.png")
