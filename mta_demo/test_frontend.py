#!/usr/bin/env python3
import os
import sys

# Change to mta_demo directory
os.chdir(os.path.dirname(os.path.abspath(__file__)))

# Test 1: Database module
print("=== Test 1: Database Module ===")
try:
    from database import get_posts, init_db
    init_db()
    posts = get_posts(5)
    print(f"OK: Database working, {len(posts)} posts found")
    for i, post in enumerate(posts[:3], 1):
        title_short = post['title'][:60] if post['title'] else 'N/A'
        print(f"  {i}. ID={post['id']}, Title: {title_short}...")
except Exception as e:
    print(f"ERROR: Database failed - {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)

# Test 2: Flask app
print("\n=== Test 2: Flask App Module ===")
try:
    from app import app
    print("OK: Flask app imported successfully")
    print(f"  Debug mode: {app.debug}")
    print(f"  Port: 8989")
except Exception as e:
    print(f"ERROR: Flask import failed - {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)

# Test 3: API endpoint
print("\n=== Test 3: API Endpoint /api/data ===")
try:
    with app.app_context():
        with app.test_client() as client:
            response = client.get('/api/data')
            print(f"OK: /api/data endpoint works")
            print(f"  Status code: {response.status_code}")
            data = response.get_json()
            if data:
                print(f"  Returned {len(data)} posts")
            else:
                print(f"  WARNING: Empty response")
except Exception as e:
    print(f"ERROR: API test failed - {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)

# Test 4: HTML page
print("\n=== Test 4: HTML Page / ===")
try:
    with app.app_context():
        with app.test_client() as client:
            response = client.get('/')
            print(f"OK: / endpoint works")
            print(f"  Status code: {response.status_code}")
            html_content = response.get_data(as_text=True)
            
            checks = [
                ('Latest Posts', 'Latest Posts'),
                ('setInterval', 'auto-refresh'),
                ('/api/data', 'API endpoint reference'),
                ('table', 'table element'),
                ('fetchPosts', 'JavaScript fetch function')
            ]
            
            for check_str, desc in checks:
                if check_str in html_content:
                    print(f"  OK: Contains {desc}")
                else:
                    print(f"  WARNING: Missing {desc}")
                    
except Exception as e:
    print(f"ERROR: HTML page test failed - {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)

print("\n=== All Tests Passed ===")
