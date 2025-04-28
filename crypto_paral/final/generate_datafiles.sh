#!/bin/bash

# 저장 경로 설정
mkdir -p datafile

# 원하는 파일 크기 (단위: KB)
sizes_kb=(1 2 4 8 16 32 64 128 256 512 1024 2048 4096 8192 10240)

# 파일 생성
for size in "${sizes_kb[@]}"; do
  file="datafile/test_${size}KB.txt"
  echo "📦 Generating $file..."
  head -c "$((size * 1024))" </dev/urandom > "$file"
done

echo "✅ 테스트 파일 생성 완료!"
