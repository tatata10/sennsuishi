import sys
import json
import re
try:
    import pdfplumber
except ImportError:
    print("pdfplumber がインストールされていません。")
    print("pip install pdfplumber を実行してください。")
    sys.exit(1)

def categorize_question(question_text):
    """問題文から自動的にカテゴリーを判定"""
    keywords = {
        "高気圧障害": ["減圧症", "窒素酔い", "酸素中毒", "スクイーズ", "エアエンボリズム"],
        "送気・器具": ["レギュレーター", "BC", "タンク", "送気", "マスク", "スクーバ"],
        "潜水業務": ["ボイル", "シャルル", "アルキメデス", "圧力", "浮力", "気体"],
        "法令": ["安全衛生規則", "労働安全", "法令", "規則", "連絡員", "作業主任者"],
        "生理": ["呼吸", "循環", "体温", "生理", "人体", "血液"]
    }
    
    for category, words in keywords.items():
        for word in words:
            if word in question_text:
                return category
    
    return "その他"

def extract_questions_from_pdf(pdf_path, output_path):
    """PDFから問題を抽出してJSON形式で保存"""
    
    questions = []
    question_count = 0
    
    print(f"PDFを読み込んでいます: {pdf_path}")
    
    with pdfplumber.open(pdf_path) as pdf:
        full_text = ""
        for page in pdf.pages:
            text = page.extract_text()
            if text:
                full_text += text + "\n"
        
        print(f"テキスト抽出完了: {len(full_text)} 文字")
        print("\n=== 抽出されたテキストのプレビュー ===")
        print(full_text[:1000])
        print("=" * 50)
        
        # 問題番号のパターンを検出
        # 一般的なパターン: "問1", "問 1", "1.", "１．" など
        question_pattern = r'(?:問|問題)\s*(\d+)|^(\d+)[\.．）\)]'
        
        # テキストを行ごとに分割
        lines = full_text.split('\n')
        
        current_question = None
        current_options = []
        
        for i, line in enumerate(lines):
            line = line.strip()
            if not line:
                continue
            
            # 問題番号を検出
            match = re.search(question_pattern, line)
            if match:
                # 前の問題を保存
                if current_question:
                    questions.append(current_question)
                
                question_count += 1
                question_id = f"202510_{question_count:02d}"
                
                # 新しい問題を開始
                current_question = {
                    "id": question_id,
                    "category": "未分類",
                    "question": "",
                    "options": [],
                    "answer_index": 0,
                    "explanation": ""
                }
                current_options = []
        
        # 最後の問題を保存
        if current_question:
            questions.append(current_question)
    
    # 年度情報を抽出（ファイル名から）
    year_match = re.search(r'(\d{4})', pdf_path)
    year = year_match.group(1) if year_match else "2025"
    
    output_data = {
        "year": year,
        "exam_date": f"{year}-10-01",
        "note": "このファイルは自動抽出されたものです。内容を確認し、必要に応じて手動で修正してください。",
        "questions": questions
    }
    
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(output_data, f, ensure_ascii=False, indent=2)
    
    print(f"\n抽出完了: {len(questions)}問を {output_path} に保存しました")
    print("\n[重要] 生成されたJSONファイルを必ず確認し、以下を手動で修正してください：")
    print("  - 問題文と選択肢の正確性")
    print("  - 正解のインデックス（answer_index）")
    print("  - カテゴリー分類")
    print("  - 解説の追加")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("使い方: python extract_questions.py <PDF_PATH> <OUTPUT_JSON_PATH>")
        print("例: python extract_questions.py pdf_source/LC20252119.pdf assets/questions/202510.json")
        sys.exit(1)
    
    pdf_path = sys.argv[1]
    output_path = sys.argv[2]
    
    extract_questions_from_pdf(pdf_path, output_path)
