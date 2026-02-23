import sys
import json
import re
try:
    import pdfplumber
except ImportError:
    print("pdfplumber がインストールされていません。")
    print("pip install pdfplumber を実行してください。")
    sys.exit(1)

def extract_questions_from_pdf_v3(pdf_path, output_path):
    """PDFから問題を抽出してJSON形式で保存（最終版）"""
    
    print(f"PDFを読み込んでいます: {pdf_path}")
    
    with pdfplumber.open(pdf_path) as pdf:
        full_text = ""
        for page in pdf.pages:
            text = page.extract_text()
            if text:
                full_text += text + "\n"
        
        print(f"テキスト抽出完了: {len(full_text)} 文字")
        
        # 問題を抽出
        questions = parse_questions_v3(full_text)
        
        # 年度情報を抽出
        year_match = re.search(r'(\d{4})', pdf_path)
        year = year_match.group(1) if year_match else "2025"
        
        output_data = {
            "year": year,
            "exam_date": f"{year}-10-01",
            "note": "このファイルは自動抽出されたものです。正解インデックスと解説は手動で追加してください。",
            "questions": questions
        }
        
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(output_data, f, ensure_ascii=False, indent=2)
        
        print(f"\n抽出完了: {len(questions)}問を {output_path} に保存しました")
        print("\n[重要] 生成されたJSONファイルを必ず確認し、以下を手動で修正してください：")
        print("  - 正解のインデックス（answer_index）← PDFの○マークを確認")
        print("  - 解説の追加（explanation）← 必要に応じて")
        print("  - カテゴリーの確認")

def parse_questions_v3(text):
    """テキストから問題を解析（改良版）"""
    questions = []
    
    # 問題を分割するパターン "問 1" や "問１" など
    pattern = r'問\s*(\d+)'
    
    # 問題ごとに分割
    parts = re.split(pattern, text)
    
    # 最初の部分は問題前の説明なのでスキップ
    for i in range(1, len(parts), 2):
        if i + 1 < len(parts):
            question_num = parts[i]
            question_text = parts[i + 1]
            
            # 問題を解析
            q = parse_single_question_v3(question_num, question_text)
            if q and q['question'] and q['options']:  # オプションがある場合のみ追加
                questions.append(q)
    
    return questions

def parse_single_question_v3(num, text):
    """単一の問題を解析（改良版）"""
    question_id = f"202510_{int(num):02d}"
    
    # 選択肢を抽出（(1), (2), (3), (4), (5) または （１）, （２）など）
    # ○マークがついている選択肢が正解
    options_pattern = r'(○?)（(\d)）\s*([^\n]+?)(?=\n|○?（\d）|問\s*\d+|$)'
    options_matches = re.findall(options_pattern, text, re.DOTALL)
    
    options = []
    answer_index = 0
    
    for i, (correct_mark, opt_num, opt_text) in enumerate(options_matches):
        # 改行や余分な空白を整理
        cleaned = ' '.join(opt_text.strip().split())
        if cleaned:
            options.append(cleaned)
            # ○マークがついている選択肢のインデックスを記録
            if correct_mark == '○':
                answer_index = i
    
    # 問題文を抽出（最初の選択肢の前まで）
    if options_matches:
        first_option_match = re.search(r'○?（\d）', text)
        if first_option_match:
            question_text = text[:first_option_match.start()].strip()
        else:
            question_text = text.strip()
    else:
        question_text = text.strip()
    
    # 改行や余分な空白を整理
    question_text = ' '.join(question_text.split())
    
    # ページ番号などの不要な情報を削除
    question_text = re.sub(r'潜水\s*\d+/\d+', '', question_text)
    question_text = re.sub(r'〔[^〕]+〕', '', question_text)  # セクション名を削除
    question_text = question_text.strip()
    
    # カテゴリーを自動判定
    category = categorize_question(question_text)
    
    return {
        "id": question_id,
        "category": category,
        "question": question_text,
        "options": options[:5],  # 最大5つまで
        "answer_index": answer_index,
        "explanation": ""
    }

def categorize_question(question_text):
    """問題文から自動的にカテゴリーを判定"""
    keywords = {
        "高気圧障害": ["減圧症", "窒素酔い", "酸素中毒", "スクイーズ", "エアエンボリズム", "減圧", "圧外傷", "肺", "心臓", "血液", "神経", "体温", "低体温", "疾病", "救命"],
        "送気・器具": ["レギュレーター", "BC", "タンク", "ボンベ", "送気", "マスク", "スクーバ", "器具", "装置", "ヘルメット", "コンプレッサー", "空気槽", "装備", "足ヒレ", "ドライスーツ"],
        "潜水業務": ["ボイル", "シャルル", "アルキメデス", "圧力", "浮力", "気体", "体積", "窒素", "酸素", "二酸化炭素", "ヘリウム", "分圧", "溶解", "光", "音", "潜水の種類", "潜降", "浮上", "潜水墜落", "吹き上げ", "溺れ", "危険性"],
        "法令": ["法令", "規則", "連絡員", "作業主任者", "義務", "禁止", "教育", "健康診断", "免許", "点検"],
    }
    
    for category, words in keywords.items():
        for word in words:
            if word in question_text:
                return category
    
    return "その他"

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("使い方: python extract_questions_v3.py <PDF_PATH> <OUTPUT_JSON_PATH>")
        print("例: python extract_questions_v3.py pdf_source/LC20252119.pdf assets/questions/202510.json")
        sys.exit(1)
    
    pdf_path = sys.argv[1]
    output_path = sys.argv[2]
    
    extract_questions_from_pdf_v3(pdf_path, output_path)
