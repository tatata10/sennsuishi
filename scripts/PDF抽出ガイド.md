# PDF問題抽出スクリプト

このスクリプトは、PDFから問題を抽出してJSON形式に変換するためのPythonスクリプトです。

## 必要なライブラリ

```bash
pip install PyPDF2 pdfplumber
```

## 使い方

```bash
python scripts/extract_questions.py pdf_source/LC20252119.pdf assets/questions/202510.json
```

## スクリプトの内容

以下のスクリプトを `scripts/extract_questions.py` として保存してください：

```python
import sys
import json
import pdfplumber
import re

def extract_questions_from_pdf(pdf_path, output_path):
    """PDFから問題を抽出してJSON形式で保存"""
    
    questions = []
    
    with pdfplumber.open(pdf_path) as pdf:
        full_text = ""
        for page in pdf.pages:
            full_text += page.extract_text() + "\n"
    
    # 問題を抽出するロジック（PDFの構造に応じて調整が必要）
    # この部分は手動で確認しながら調整してください
    
    # 出力JSONの構造
    output_data = {
        "year": "2025",
        "exam_date": "2025-10-01",  # 実際の試験日に修正
        "questions": questions
    }
    
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(output_data, f, ensure_ascii=False, indent=2)
    
    print(f"抽出完了: {len(questions)}問を {output_path} に保存しました")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("使い方: python extract_questions.py <PDF_PATH> <OUTPUT_JSON_PATH>")
        sys.exit(1)
    
    pdf_path = sys.argv[1]
    output_path = sys.argv[2]
    
    extract_questions_from_pdf(pdf_path, output_path)
```

## 手動での抽出方法

PDFの内容を確認しながら、以下のJSON形式で手動入力することも可能です：

```json
{
  "year": "2025",
  "exam_date": "2025-10-01",
  "questions": [
    {
      "id": "202510_01",
      "category": "高気圧障害",
      "question": "問題文をここに入力",
      "options": [
        "選択肢1",
        "選択肢2",
        "選択肢3",
        "選択肢4",
        "選択肢5"
      ],
      "answer_index": 0,
      "explanation": "解説をここに入力（なければ空文字列）"
    }
  ]
}
```

## 次のステップ

1. PDFの内容を確認
2. 上記のスクリプトを使用するか、手動でJSON作成
3. `assets/questions/202510.json` に保存
4. アプリで読み込み機能を実装
