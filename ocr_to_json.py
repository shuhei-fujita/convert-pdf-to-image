import os
import json
from PIL import Image
import pytesseract
import time

# OCR対象の画像ディレクトリ
INPUT_DIR = "./output"
OUTPUT_JSON = "ocr_dump.json"

# 言語設定（韓国語＋英語）
OCR_LANG = "kor+eng"

def extract_text_from_images(input_dir):
    results = []
    
    # PNGファイルのみを取得してソート
    image_files = [f for f in sorted(os.listdir(input_dir)) 
                   if f.lower().endswith(".png")]
    
    if not image_files:
        print("⚠️  画像ファイルが見つかりません")
        return results
    
    print(f"📋 OCR対象ファイル: {len(image_files)}件")
    print("")
    
    for i, filename in enumerate(image_files, 1):
        path = os.path.join(input_dir, filename)
        
        # ファイルサイズを確認
        file_size = os.path.getsize(path) / (1024 * 1024)  # MB
        print(f"[{i}/{len(image_files)}] OCR中: {filename} ({file_size:.1f}MB)")
        
        start_time = time.time()
        
        try:
            # 画像を読み込み
            img = Image.open(path)
            
            # 大きな画像の場合はリサイズ（高速化）
            if img.size[0] > 2000 or img.size[1] > 2000:
                print(f"    🔄 リサイズ中... ({img.size[0]}x{img.size[1]} → 2000x2000以下)")
                img.thumbnail((2000, 2000), Image.Resampling.LANCZOS)
            
            # OCR実行
            text = pytesseract.image_to_string(img, lang=OCR_LANG)
            
            elapsed_time = time.time() - start_time
            print(f"    ✅ 完了 ({elapsed_time:.1f}秒)")
            
            results.append({
                "filename": filename,
                "text": text.strip(),
                "processing_time": elapsed_time,
                "file_size_mb": file_size
            })
            
        except Exception as e:
            elapsed_time = time.time() - start_time
            print(f"    ❌ エラー ({elapsed_time:.1f}秒): {str(e)}")
            
            results.append({
                "filename": filename,
                "error": str(e),
                "processing_time": elapsed_time,
                "file_size_mb": file_size
            })
    
    return results

def save_as_json(data, output_path):
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

if __name__ == "__main__":
    print("🔍 OCR処理を開始します...")
    print(f"📂 入力フォルダ: {INPUT_DIR}")
    print(f"📄 出力ファイル: {OUTPUT_JSON}")
    print("")
    
    extracted_data = extract_text_from_images(INPUT_DIR)
    
    if extracted_data:
        save_as_json(extracted_data, OUTPUT_JSON)
        
        # 統計情報
        success_count = len([d for d in extracted_data if "error" not in d])
        error_count = len([d for d in extracted_data if "error" in d])
        total_time = sum(d.get("processing_time", 0) for d in extracted_data)
        
        print("")
        print("📊 OCR処理完了")
        print(f"  ✅ 成功: {success_count}件")
        print(f"  ❌ エラー: {error_count}件")
        print(f"  ⏱️  総処理時間: {total_time:.1f}秒")
        print(f"  💾 結果を {OUTPUT_JSON} に保存しました")
    else:
        print("⚠️  処理対象のファイルがありませんでした")
