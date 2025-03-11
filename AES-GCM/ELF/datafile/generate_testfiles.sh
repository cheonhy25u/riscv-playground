#!/bin/bash
# 테스트 파일 자동 생성 스크립트
# KB 단위로 파일명을 통일하여 생성

# 저장할 디렉토리
DATA_DIR="."

# 디렉토리가 없으면 생성
mkdir -p "${DATA_DIR}"

# 생성할 데이터 크기 (KB 단위)
sizes=(1 10 100 1024 10240 52428 104857 524288)  # 1KB ~ 500MB

# 파일 생성
for size in "${sizes[@]}"; do
  file="${DATA_DIR}/test_${size}KB.txt"
  if [ ! -f "$file" ]; then
    echo "Generating $file..."
    head -c "$((size * 1024))" </dev/urandom > "$file"
  else
    echo "$file already exists. Skipping."
  fi
done

echo "All test files are generated in ${DATA_DIR}/"
