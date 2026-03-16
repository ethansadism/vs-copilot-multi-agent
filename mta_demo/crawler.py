import time
import requests
import schedule
import logging
from datetime import datetime
import sys
import os

# Add the current directory to sys.path to ensure local imports work
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

try:
    import database
except ImportError:
    # Fallback for when running as module
    from mta_demo import database

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

HN_API_BASE = "https://hacker-news.firebaseio.com/v0"

def fetch_top_stories():
    """Fetch top 10 stories from Hacker News and save to DB."""
    logger.info("Starting crawl of HN top stories...")
    
    try:
        # 1. Get top stories IDs
        resp = requests.get(f"{HN_API_BASE}/topstories.json", timeout=10)
        resp.raise_for_status()
        top_ids = resp.json()[:10]  # Get first 10
        
        count = 0
        for story_id in top_ids:
            try:
                # 2. Get story details
                story_resp = requests.get(f"{HN_API_BASE}/item/{story_id}.json", timeout=10)
                story_resp.raise_for_status()
                story = story_resp.json()
                
                # Skip if no URL (e.g. Ask HN)
                if 'url' not in story:
                    continue
                    
                title = story.get('title', 'No Title')
                url = story.get('url')
                timestamp = story.get('time', time.time())
                published_at = datetime.fromtimestamp(timestamp).isoformat()
                
                # 3. Save to DB
                if database.insert_post(title, url, published_at):
                    logger.info(f"Saved: {title}")
                    count += 1
                else:
                    logger.debug(f"Duplicate/Skipped: {title}")
                    
            except Exception as e:
                logger.error(f"Error fetching story {story_id}: {e}")
                
        logger.info(f"Crawl finished. Added {count} new stories.")
        
    except Exception as e:
        logger.error(f"Critical error in crawler: {e}")

def main():
    # Ensure DB is initialized
    database.init_db()
    
    # Run once immediately
    fetch_top_stories()
    
    # Schedule every 5 minutes
    schedule.every(5).minutes.do(fetch_top_stories)
    
    logger.info("Scheduler started. Press Ctrl+C to exit.")
    
    while True:
        schedule.run_pending()
        time.sleep(1)

if __name__ == "__main__":
    main()
