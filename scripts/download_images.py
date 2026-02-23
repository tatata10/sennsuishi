import os
import requests
from bs4 import BeautifulSoup
import time

def download_images():
    exams = ['2570', '2571', '2572', '2573', '2574', '2575', '2576', '2577', '2578', '2579', '2580', '2581']
    os.makedirs('assets/questions/images', exist_ok=True)
    
    for eid in exams:
        print(f"Exam: {eid}")
        for qno in range(1, 41):
            url = f"https://fun-learning.jp/app/learnings/ex/{eid}/{qno}"
            try:
                r = requests.get(url, timeout=10)
                if r.status_code != 200:
                    continue
                
                s = BeautifulSoup(r.text, 'html.parser')
                div = s.find('div', class_='pnl-q-img')
                if div:
                    img = div.find('img')
                    if img and 'src' in img.attrs:
                        src = img['src']
                        full_src = 'https:' + src if src.startswith('//') else src
                        filename = f"assets/questions/images/{eid}_{qno}.jpg"
                        
                        # Check if already exists to save time
                        if os.path.exists(filename):
                            print(f"  Q{qno}: Already exists")
                            continue
                            
                        print(f"  Q{qno}: Fetching {full_src}")
                        r_img = requests.get(full_src, timeout=10)
                        if r_img.status_code == 200:
                            with open(filename, 'wb') as f:
                                f.write(r_img.content)
                            print(f"    Saved to {filename}")
                        
                        time.sleep(0.1)
            except Exception as e:
                print(f"  Q{qno}: Error {e}")
                continue

if __name__ == "__main__":
    download_images()
