import os
import json
import glob
from supabase import create_client, Client

# --- Configuration ---
# It's better to use environment variables for production, 
# but for local tool use, we can take from config or constants.
SUPABASE_URL = "https://kcrgjwlrtdxqeahqfvny.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imtjcmdqd2xydGR4cWVhaHFmdm55Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE4MTQyMjIsImV4cCI6MjA4NzM5MDIyMn0.lXfE_rgj2QN9KFq7d1FSPe-ExAGjgFVeUbx4dcmYCJ0"

# Path to the scraped JSON files
QUESTIONS_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'assets', 'questions'))

def map_category(categories):
    """Maps list of categories from scraper to a single standard category."""
    if not categories or not isinstance(categories, list):
        return "その他"
    
    mapping = {
        '潜水業務': '潜水業務',
        '送気、潜降及び浮上': '送気・器具',
        '送気・器具': '送気・器具',
        '高気圧障害': '高気圧障害',
        '関係法令': '法令',
        '法令': '法令',
    }
    
    for key, val in mapping.items():
        if key in categories:
            return val
    return categories[0] if categories else "その他"

def sync_questions():
    print(f"Connecting to Supabase at {SUPABASE_URL}...")
    supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
    
    json_files = glob.glob(os.path.join(QUESTIONS_DIR, 'scraped_*.json'))
    print(f"Found {len(json_files)} question files.")
    
    all_questions = {}
    
    for file_path in json_files:
        # Ignore the combined file to avoid duplication
        if 'all_scraped_questions' in file_path:
            continue
            
        exam_id = os.path.basename(file_path).replace('scraped_', '').replace('.json', '')
        print(f"Processing exam ID: {exam_id}...")
        
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
            questions = data.get('questions', [])
            
            for q in questions:
                # Generate unique ID if not present
                q_id = q.get('id')
                if not q_id:
                    import re
                    no_str = str(q.get('no', '0'))
                    match = re.search(r'\d+', no_str)
                    q_no = match.group(0) if match else "0"
                    q_id = f"{exam_id}_{q_no}"
                
                img_url = q.get("image_url", "")
                
                # Use local paths for Web performance and to avoid CORS
                # assets/questions/images/EXAMID_QNO.jpg
                if img_url:
                    import re
                    no_str = str(q.get('no', '0'))
                    match = re.search(r'\d+', no_str)
                    q_no = match.group(0) if match else "0"
                    img_url = f"assets/questions/images/{exam_id}_{q_no}.jpg"

                # Format for Supabase
                formatted_q = {
                    "id": q_id,
                    "category": map_category(q.get('categories', [])),
                    "question": q.get("question", ""),
                    "options": q.get("options", []),
                    "answer_index": q.get("answer_index", 0),
                    "explanation": q.get("explanation", ""),
                    "image_url": img_url
                }
                all_questions[q_id] = formatted_q
    
    upload_list = list(all_questions.values())
    if not upload_list:
        print("No questions found to upload.")
        return

    print(f"Uploading {len(upload_list)} unique questions to Supabase (upsert)...")
    
    batch_size = 100
    for i in range(0, len(upload_list), batch_size):
        batch = upload_list[i:i + batch_size]
        try:
            response = supabase.table("questions").upsert(batch).execute()
            print(f"  Uploaded batch {i//batch_size + 1}/{(len(all_questions)-1)//batch_size + 1}")
        except Exception as e:
            print(f"  Error uploading batch {i//batch_size + 1}: {e}")

    print("Sync complete.")

if __name__ == "__main__":
    sync_questions()
