import requests
import feedparser
import yaml
import sys

sys.stdout.reconfigure(encoding='utf-8')

def test_rss():
    with open("sources.yaml", "r", encoding="utf-8") as f:
        config = yaml.safe_load(f)
        
    blogs = config.get("blogs", [])
    
    print("=========================================")
    print("        네이버 블로그 RSS 접근성 점검")
    print("=========================================\n")
    
    for blog in blogs:
        name = blog.get("name")
        rss_url = blog.get("rss")
        
        print(f"[{name}] 점검 중: {rss_url}")
        
        try:
            # 1. HTTP 응답 점검
            response = requests.get(rss_url, timeout=10)
            status_code = response.status_code
            print(f"  -> HTTP 응답 상태: {status_code}")
            
            # 2. feedparser 구문 분석 점검
            feed = feedparser.parse(rss_url)
            posts = feed.entries
            post_count = len(posts)
            print(f"  -> 수집 가능한 글 개수: {post_count}")
            
            # 3. 최신 글 3개 제목 출력
            if post_count > 0:
                print("  -> 최신 글 3개 제목:")
                for idx, entry in enumerate(posts[:3]):
                    print(f"    {idx+1}. {entry.get('title', '제목 없음')}")
            else:
                print("  -> 경고: 수집된 글이 없습니다.")
                
        except Exception as e:
            print(f"  -> 오류 발생: {e}")
            
        print("\n" + "-"*40 + "\n")

if __name__ == "__main__":
    test_rss()
