#!/bin/bash

# デフォルトの入力・出力フォルダ（相対パス）
INPUT_DIR="./input"
OUTPUT_DIR="./output"
DRY_RUN=false

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
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    -h|--help)
      echo "使用方法: $0 [-i INPUT_DIR] [-o OUTPUT_DIR] [--dry-run]"
      echo "  -i, --input    入力フォルダ（デフォルト: ./input）"
      echo "  -o, --output   出力フォルダ（デフォルト: ./output）"
      echo "  --dry-run      実際の変換を行わず、実行予定の内容を表示"
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
  if [[ "$DRY_RUN" == true ]]; then
    echo "📁 [DRY RUN] 入力フォルダを作成: $INPUT_DIR"
  else
    echo "📁 入力フォルダを作成: $INPUT_DIR"
    mkdir -p "$INPUT_DIR"
  fi
fi

# 出力フォルダが存在しない場合は作成
if [[ ! -d "$OUTPUT_DIR" ]]; then
  if [[ "$DRY_RUN" == true ]]; then
    echo "📁 [DRY RUN] 出力フォルダを作成: $OUTPUT_DIR"
  else
    echo "📁 出力フォルダを作成: $OUTPUT_DIR"
    mkdir -p "$OUTPUT_DIR"
  fi
fi

echo "📂 入力フォルダ: $INPUT_DIR"
echo "📂 出力フォルダ: $OUTPUT_DIR"
if [[ "$DRY_RUN" == true ]]; then
  echo "🔍 DRY RUN モード: 実際の変換は実行されません"
fi
echo ""

# 変換対象ファイルのリストを作成
pdf_files=()
while IFS= read -r -d '' file; do
  pdf_files+=("$file")
done < <(find "$INPUT_DIR" -maxdepth 1 -iname "*.pdf" -print0)

if [[ ${#pdf_files[@]} -eq 0 ]]; then
  echo "⚠️  変換対象のPDFファイルが見つかりません: $INPUT_DIR"
  exit 0
fi

echo "📋 変換対象ファイル (${#pdf_files[@]}件):"
for pdf in "${pdf_files[@]}"; do
  filename=$(basename "$pdf" .pdf)
  output="$OUTPUT_DIR/${filename}.png"
  echo "  📄 $pdf → $output"
done
echo ""

# 変換処理
converted_count=0
failed_count=0

for pdf in "${pdf_files[@]}"; do
  filename=$(basename "$pdf" .pdf)
  output="$OUTPUT_DIR/${filename}.png"

  if [[ "$DRY_RUN" == true ]]; then
    echo "🔄 [DRY RUN] 変換予定: $pdf → $output"
    ((converted_count++))
  else
    echo "🔄 変換中: $pdf → $output"

    # ImageMagick で PDF → PNG（1ページ目のみ）
    if magick -density 300 "${pdf}[0]" -resize 2000x "$output"; then
      echo "✅ 完了: $output"
      ((converted_count++))
    else
      echo "❌ 変換失敗: $pdf"
      ((failed_count++))
    fi
  fi
done

echo ""

# 結果サマリー
if [[ "$DRY_RUN" == true ]]; then
  echo "📊 [DRY RUN] 実行予定サマリー:"
  echo "  📄 変換予定: ${#pdf_files[@]}件"
else
  echo "📊 実行結果サマリー:"
  echo "  ✅ 成功: $converted_count件"
  echo "  ❌ 失敗: $failed_count件"
fi
