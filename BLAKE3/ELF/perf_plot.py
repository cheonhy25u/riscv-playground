import pandas as pd
import matplotlib.pyplot as plt

# CSV 파일 로드
df = pd.read_csv("perf_results.csv")

# 파일 크기를 MB 단위로 변환
df["FileSizeMB"] = df["FileSizeKB"] / 1024.0

# 실행 파일명 간소화 (경로 및 옵션 제거)
df["ExecName"] = df["ExecName"].apply(lambda x: x.split("/")[-1].split(" ")[0])

# 성능 지표 목록
metrics = {
    "TaskClock": "Task Clock (msec)",
    "Cycles": "Cycles",
    "PageFaults": "Page Faults",
    "CpuClock": "CPU Clock (msec)"
}

# 실행 파일 목록
executables = df["ExecName"].unique()

# 각 성능 지표별 그래프 생성
for metric, ylabel in metrics.items():
    plt.figure(figsize=(8, 6))

    for exe in executables:
        sub_df = df[df["ExecName"] == exe].sort_values("FileSizeMB")
        plt.plot(sub_df["FileSizeMB"], sub_df[metric], marker="o", label=exe)

    # 그래프 설정
    plt.xlabel("Input File Size (MB)")
    plt.ylabel(ylabel)
    plt.title(f"{ylabel} vs. Input File Size (MB)")
    plt.legend(title="Executable", loc="best", fontsize=10)  # 범례 간결화
    plt.grid(True)
    plt.xscale("log")  # 로그 스케일 적용 (파일 크기 변화 가독성 증가)

    # 그래프 저장
    plt.savefig(f"{metric}_vs_FileSizeMB.png")
    plt.close()

print("✅ Graphs saved as *_vs_FileSizeMB.png")
