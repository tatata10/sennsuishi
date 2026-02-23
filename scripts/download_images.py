import json
import os
import requests
import re
from urllib.parse import urlparse

def download_images_for_exams():
    questions_dir = "assets/questions"
    images_dir = os.path.join(questions_dir, "images")
    os.makedirs(images_dir, exist_ok=True)

    # JSONファイルの一覧を取得
    json_files = [f for f in os.listdir(questions_dir) if f.startswith("scraped_") and f.endswith(".json")]

    for json_file in json_files:
        filepath = os.path.join(questions_dir, json_file)
        print(f"Processing {json_file}...")
        
        with open(filepath, 'r', encoding='utf-8') as f:
            data = f.read()
            if not data:
                continue
            exam_data = json.loads(data)

        exam_id = exam_data.get("id", "unknown")
        updated = False

        for q in exam_data.get("questions", []):
            img_url = q.get("image_url")
            if img_url and img_url.startswith("http"):
                # 画像の拡張子を取得
                parsed_url = urlparse(img_url)
                ext = os.path.splitext(parsed_url.path)[1]
                if not ext:
                    ext = ".jpg" # デフォルト
                
                # 問題番号から数字を抽出
                q_no_match = re.search(r'\d+', q.get("no", ""))
                q_no = q_no_match.group(0) if q_no_match else "unknown"
                
                # 保存ファイル名: {exam_id}_{q_no}{ext}
                image_filename = f"{exam_id}_{q_no}{ext}"
                local_image_path = os.path.join(images_dir, image_filename)
                
                # 相対パス（assets/questions/images/filename）をJSONに保存
                relative_path = f"assets/questions/images/{image_filename}"

                try:
                    print(f"  Downloading: {img_url} -> {local_image_path}")
                    response = requests.get(img_url, timeout=10)
                    if response.status_code == 200:
                        with open(local_image_path, 'wb') as img_f:
                            img_f.write(response.content)
                        # JSONのパスを更新
                        q["image_url"] = relative_path
                        updated = True
                    else:
                        print(f"  Failed to download: {img_url} (Status: {response.status_code})")
                except Exception as e:
                    print(f"  Error downloading {img_url}: {e}")

        if updated:
            with open(filepath, 'w', encoding='utf-8') as f:
                json.dump(exam_data, f, ensure_ascii=False, indent=2)
            print(f"  Updated and saved {json_file}")

    # all_scraped_questions.json も更新する必要があるかもしれない
    update_compiled_json(questions_dir)

def update_compiled_json(questions_dir):
    compiled_path = os.path.join(questions_dir, "all_scraped_questions.json")
    if not os.path.exists(compiled_path):
        return

    print("Updating compiled JSON...")
    all_data = []
    json_files = [f for f in os.listdir(questions_dir) if f.startswith("scraped_") and f.endswith(".json")]
    
    # 年度順などにソート（必要なら）
    json_files.sort(reverse=True)

    for json_file in json_files:
        filepath = os.path.join(questions_dir, json_file)
        with open(filepath, 'r', encoding='utf-8') as f:
            all_data.append(json.load(f))

    with open(compiled_path, 'w', encoding='utf-8') as f:
        json.dump(all_data, f, ensure_ascii=False, indent=2)
    print("Compiled JSON updated.")

if __name__ == "__main__":
    download_images_for_exams()
