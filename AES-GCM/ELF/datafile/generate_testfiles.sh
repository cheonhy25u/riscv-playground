#!/bin/bash
# 테스트 파일 자동 생성 스크립트 (KB 단위, 실수 지원)

# 저장할 디렉토리
DATA_DIR="."

# 디렉토리 생성
mkdir -p "${DATA_DIR}"

# 생성할 데이터 크기 (KB 단위, 실수 포함)
sizes=(0.5 1 2 3 4 6 8 16 32 48 64 96 128 256 384 512 768 1024 1536 2048 3072 4096)

# 파일 생성
for size in "${sizes[@]}"; do
  file="${DATA_DIR}/test_${size}KB.txt"
  if [ ! -f "$file" ]; then
    # 소수 포함 size 계산: awk 사용
    bytes=$(awk "BEGIN {printf \"%d\", $size * 1024}")
    echo "Generating $file ($bytes bytes)..."
    head -c "$bytes" </dev/urandom > "$file"
  else
    echo "$file already exists. Skipping."
  fi
done

echo "✅ All test files are generated in ${DATA_DIR}/"
