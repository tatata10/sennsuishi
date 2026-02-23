import sys
import json
import re
try:
    import pdfplumber
except ImportError:
    print("pdfplumber がインストールされていません。")
    print("pip install pdfplumber を実行してください。")
    sys.exit(1)

def extract_questions_from_pdf_v2(pdf_path, output_path):
    """PDFから問題を抽出してJSON形式で保存（改良版）"""
    
    print(f"PDFを読み込んでいます: {pdf_path}")
    
    with pdfplumber.open(pdf_path) as pdf:
        full_text = ""
        for page in pdf.pages:
            text = page.extract_text()
            if text:
                full_text += text + "\n"
        
        print(f"テキスト抽出完了: {len(full_text)} 文字")
        
        # デバッグ用にテキストをファイルに保存
        debug_file = output_path.replace('.json', '_debug.txt')
        with open(debug_file, 'w', encoding='utf-8') as f:
            f.write(full_text)
        print(f"デバッグ用テキストを保存: {debug_file}")
        
        # 問題を抽出
        questions = parse_questions(full_text)
        
        # 年度情報を抽出
        year_match = re.search(r'(\d{4})', pdf_path)
        year = year_match.group(1) if year_match else "2025"
        
        output_data = {
            "year": year,
            "exam_date": f"{year}-10-01",
            "note": "このファイルは自動抽出されたものです。必ず内容を確認し、修正してください。",
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

def parse_questions(text):
    """テキストから問題を解析"""
    questions = []
    
    # 問題を分割するパターン
    # "問 1" や "問1" のようなパターンで分割
    pattern = r'問\s*(\d+)'
    
    # 問題ごとに分割
    parts = re.split(pattern, text)
    
    # 最初の部分は問題前の説明なのでスキップ
    for i in range(1, len(parts), 2):
        if i + 1 < len(parts):
            question_num = parts[i]
            question_text = parts[i + 1]
            
            # 問題を解析
            q = parse_single_question(question_num, question_text)
            if q:
                questions.append(q)
    
    return questions

def parse_single_question(num, text):
    """単一の問題を解析"""
    question_id = f"202510_{int(num):02d}"
    
    # 選択肢を抽出（(1), (2), (3), (4), (5) のパターン）
    options_pattern = r'\((\d)\)\s*([^\(]+?)(?=\(\d\)|$)'
    options_matches = re.findall(options_pattern, text, re.DOTALL)
    
    options = []
    for opt_num, opt_text in options_matches:
        # 改行や余分な空白を整理
        cleaned = ' '.join(opt_text.strip().split())
        if cleaned and len(cleaned) > 3:  # 短すぎる選択肢は除外
            options.append(cleaned)
    
    # 問題文を抽出（最初の選択肢の前まで）
    if options_matches:
        first_option_pos = text.find(f'({options_matches[0][0]})')
        question_text = text[:first_option_pos].strip()
    else:
        question_text = text.strip()
    
    # 改行や余分な空白を整理
    question_text = ' '.join(question_text.split())
    
    # カテゴリーを自動判定
    category = categorize_question(question_text)
    
    return {
        "id": question_id,
        "category": category,
        "question": question_text,
        "options": options[:5],  # 最大5つまで
        "answer_index": 0,  # デフォルト値、手動で修正が必要
        "explanation": ""
    }

def categorize_question(question_text):
    """問題文から自動的にカテゴリーを判定"""
    keywords = {
        "高気圧障害": ["減圧症", "窒素酔い", "酸素中毒", "スクイーズ", "エアエンボリズム", "減圧"],
        "送気・器具": ["レギュレーター", "BC", "タンク", "送気", "マスク", "スクーバ", "器具", "装置"],
        "潜水業務": ["ボイル", "シャルル", "アルキメデス", "圧力", "浮力", "気体", "体積"],
        "法令": ["安全衛生規則", "労働安全", "法令", "規則", "連絡員", "作業主任者", "義務"],
        "生理": ["呼吸", "循環", "体温", "生理", "人体", "血液", "心臓"]
    }
    
    for category, words in keywords.items():
        for word in words:
            if word in question_text:
                return category
    
    return "その他"

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("使い方: python extract_questions_v2.py <PDF_PATH> <OUTPUT_JSON_PATH>")
        print("例: python extract_questions_v2.py pdf_source/LC20252119.pdf assets/questions/202510.json")
        sys.exit(1)
    
    pdf_path = sys.argv[1]
    output_path = sys.argv[2]
    
    extract_questions_from_pdf_v2(pdf_path, output_path)
