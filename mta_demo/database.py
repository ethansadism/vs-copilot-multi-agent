import sqlite3
import os
from datetime import datetime
from contextlib import closing

# Build the absolute path to the database file ensuring it is in the same directory as this module
DB_FILE = os.path.join(os.path.dirname(__file__), 'crawler.db')

def get_connection():
    conn = sqlite3.connect(DB_FILE)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    create_table_sql = '''
    CREATE TABLE IF NOT EXISTS posts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        url TEXT UNIQUE,
        published_at TEXT,
        crawled_at TEXT
    );
    '''
    with closing(get_connection()) as conn:
        with conn:
            conn.execute(create_table_sql)

def insert_post(title, url, published_at):
    crawled_at = datetime.now().isoformat()
    insert_sql = '''
    INSERT INTO posts (title, url, published_at, crawled_at)
    VALUES (?, ?, ?, ?)
    '''
    try:
        with closing(get_connection()) as conn:
            with conn:
                conn.execute(insert_sql, (title, url, published_at, crawled_at))
        return True
    except sqlite3.IntegrityError:
        return False

def get_posts(limit=20):
    select_sql = '''
    SELECT id, title, url, published_at, crawled_at
    FROM posts
    ORDER BY crawled_at DESC
    LIMIT ?
    '''
    with closing(get_connection()) as conn:
        cursor = conn.execute(select_sql, (limit,))
        posts = [dict(row) for row in cursor.fetchall()]
        return posts

if __name__ == "__main__":
    init_db()
    print(f"Database initialized at: {DB_FILE}")
