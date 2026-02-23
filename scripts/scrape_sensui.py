import requests
from bs4 import BeautifulSoup
import json
import re
import time
import os

def scrape_exam(exam_url_base, exam_id):
    questions = []
    # 通常40問らしいが、念のためループ
    for page in range(1, 41):
        url = f"{exam_url_base}/{page}"
        print(f"Scraping: {url}", flush=True)
        
        try:
            response = requests.get(url)
            response.encoding = 'utf-8'
            if response.status_code != 200:
                print(f"Finished at page {page-1} for {exam_id}")
                break
                
            soup = BeautifulSoup(response.text, 'html.parser')
            
            # 問題文
            q_word_div = soup.find('div', class_='question-word')
            q_text = ""
            if q_word_div:
                p_tag = q_word_div.find('p')
                if p_tag:
                    q_text = p_tag.get_text(strip=True)
            
            # 画像
            img_div = soup.find('div', class_='pnl-q-img')
            img_url = ""
            if img_div:
                img_tag = img_div.find('img')
                if img_tag and 'src' in img_tag.attrs:
                    img_url = img_tag['src']
                    if img_url.startswith('//'):
                        img_url = 'https:' + img_url
            
            # 選択肢
            options = []
            table = soup.find('table', id='question-lists')
            if table:
                tds = table.find_all('td')
                for td in tds:
                    opt_text = td.get_text(separator=' ', strip=True)
                    # 余分な空白や改行を整理
                    opt_text = ' '.join(opt_text.split())
                    options.append(opt_text)
            
            # 正解 (JSから抽出)
            # if ( $(elem).attr('id') == 322721 ) return true;
            # などのパターンを探す
            scripts = soup.find_all('script')
            correct_id = None
            for script in scripts:
                if script.string and 'check_answers' in script.string:
                    match = re.search(r"\.attr\('id'\) == (\d+)", script.string)
                    if match:
                        correct_id = match.group(1)
            
            answer_index = -1
            if correct_id and table:
                # TDのIDと一致するものを探す
                for i, td in enumerate(table.find_all('td')):
                    if td.get('id') == correct_id:
                        answer_index = i
                        break
            
            # カテゴリー
            categories = []
            category_tags = soup.find_all('span', class_='badge')
            for tag in category_tags:
                tag_text = tag.get_text(strip=True)
                if tag_text not in categories:
                    categories.append(tag_text)
            
            # 問題番号
            # "問題．1 / 40　覚えた数 : -" などの文字列から "問題．1" を抽出
            h2_title = soup.find('h2')
            q_no_text = h2_title.get_text(strip=True) if h2_title else f"問題．{page}"
            q_no_match = re.search(r'(問題\D*\d+)', q_no_text)
            if q_no_match:
                q_no_text = q_no_match.group(1)

            # 解説
            explanation = ""
            exp_div = soup.find('div', class_='question-desc')
            if exp_div:
                exp_p = exp_div.find('p')
                if exp_p:
                    explanation = exp_p.get_text(strip=True)
                    if "解説はありません" in explanation:
                        explanation = ""

            questions.append({
                "no": q_no_text,
                "question": q_text,
                "image_url": img_url,
                "options": options,
                "answer_index": answer_index,
                "categories": categories,
                "explanation": explanation,
                "url": url
            })
            
            # サーバーに負荷をかけないよう少し待つ
            time.sleep(0.5)
            
        except Exception as e:
            print(f"Error scraping {url}: {e}", flush=True)
            break
            
    return questions

def main():
    base_url = "https://fun-learning.jp/wp/sensui/"
    print(f"Fetching exam list from {base_url}...", flush=True)
    response = requests.get(base_url)
    response.encoding = 'utf-8'
    soup = BeautifulSoup(response.text, 'html.parser')
    
    # 年別のリンクを取得
    exam_links = []
    # [潜水士試験（令和7年10月）](https://fun-learning.jp/app/learnings/ex/2581)
    # のようなリンクを探す
    for a in soup.find_all('a', href=re.compile(r'/app/learnings/ex/\d+')):
        title = a.get_text(strip=True)
        if title and "潜水士試験" in title:
            exam_links.append({
                "title": title,
                "url": a['href']
            })
    
    # 重複削除
    seen_urls = set()
    unique_links = []
    for link in exam_links:
        if link['url'] not in seen_urls:
            unique_links.append(link)
            seen_urls.add(link['url'])
            
    print(f"Found {len(unique_links)} exams.", flush=True)
    
    all_data = []
    
    # 全ての試験を処理
    for link in unique_links:
        print(f"\nProcessing {link['title']}...", flush=True)
        exam_id = link['url'].split('/')[-1]
        questions = scrape_exam(link['url'], exam_id)
        
        exam_data = {
            "title": link['title'],
            "id": exam_id,
            "questions": questions
        }
        all_data.append(exam_data)
        
        # 途中経過保存
        filename = f"assets/questions/scraped_{exam_id}.json"
        os.makedirs("assets/questions", exist_ok=True)
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(exam_data, f, ensure_ascii=False, indent=2)
        print(f"Saved: {filename}", flush=True)

    # 全体保存
    with open("assets/questions/all_scraped_questions.json", 'w', encoding='utf-8') as f:
        json.dump(all_data, f, ensure_ascii=False, indent=2)
    print("\nAll processing complete.", flush=True)

if __name__ == "__main__":
    main()
