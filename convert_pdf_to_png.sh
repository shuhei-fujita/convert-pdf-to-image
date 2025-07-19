#!/bin/bash

# デフォルトの入力・出力フォルダ（相対パス）
INPUT_DIR="./input"
OUTPUT_DIR="./output"

# コマンドライン引数の処理
while [[ $# -gt 0 ]]; do
  case $1 in
    -i|--input)
      INPUT_DIR="$2"
      shift 2
      ;;
    -o|--output)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    -h|--help)
      echo "使用方法: $0 [-i INPUT_DIR] [-o OUTPUT_DIR]"
      echo "  -i, --input    入力フォルダ（デフォルト: ./input）"
      echo "  -o, --output   出力フォルダ（デフォルト: ./output）"
      echo "  -h, --help     このヘルプを表示"
      exit 0
      ;;
    *)
      echo "不明なオプション: $1"
      echo "使用方法: $0 --help"
      exit 1
      ;;
  esac
done

# 入力フォルダが存在しない場合は作成
if [[ ! -d "$INPUT_DIR" ]]; then
  echo "📁 入力フォルダを作成: $INPUT_DIR"
  mkdir -p "$INPUT_DIR"
fi

# 出力フォルダが存在しない場合は作成
if [[ ! -d "$OUTPUT_DIR" ]]; then
  echo "📁 出力フォルダを作成: $OUTPUT_DIR"
  mkdir -p "$OUTPUT_DIR"
fi

echo "📂 入力フォルダ: $INPUT_DIR"
echo "📂 出力フォルダ: $OUTPUT_DIR"

# ファイル名に空白がある場合に備えて find と read で処理
find "$INPUT_DIR" -maxdepth 1 -iname "*.pdf" | while IFS= read -r pdf; do
  filename=$(basename "$pdf" .pdf)
  output="$OUTPUT_DIR/${filename}.png"

  echo "🔄 変換中: $pdf → $output"

  # ImageMagick で PDF → PNG（1ページ目のみ）
  magick -density 300 "${pdf}[0]" -resize 2000x "$output"

  if [[ $? -eq 0 ]]; then
    echo "✅ 完了: $output"
  else
    echo "❌ 変換失敗: $pdf"
  fi
done
