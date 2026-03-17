"""
mta_demo3 — GitHub Trending 爬蟲資料庫模組
使用 SQLite3 儲存每次爬取的 Trending repos（保留完整歷史）
"""

import sqlite3
import os
from datetime import datetime
from contextlib import closing


def _get_connection(db_path: str):
    """取得 SQLite 連線，啟用 WAL 模式提升並發讀取效能"""
    # 確保資料庫目錄存在
    db_dir = os.path.dirname(db_path)
    if db_dir:
        os.makedirs(db_dir, exist_ok=True)

    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL")
    return conn


def init_db(db_path: str = "trending.db") -> None:
    """建立資料表與索引（idempotent，執行多次不報錯）"""
    with closing(_get_connection(db_path)) as conn:
        with conn:
            conn.execute('''
                CREATE TABLE IF NOT EXISTS trending_repos (
                    id          INTEGER PRIMARY KEY AUTOINCREMENT,
                    author      TEXT NOT NULL,
                    repo_name   TEXT NOT NULL,
                    full_name   TEXT NOT NULL,
                    description TEXT,
                    language    TEXT,
                    stars_today INTEGER DEFAULT 0,
                    total_stars INTEGER DEFAULT 0,
                    forks       INTEGER DEFAULT 0,
                    repo_url    TEXT NOT NULL,
                    crawled_at  TEXT NOT NULL,
                    batch_id    TEXT NOT NULL
                )
            ''')
            conn.execute('''
                CREATE INDEX IF NOT EXISTS idx_trending_batch
                ON trending_repos (batch_id)
            ''')
            conn.execute('''
                CREATE INDEX IF NOT EXISTS idx_trending_language
                ON trending_repos (language)
            ''')
            conn.execute('''
                CREATE INDEX IF NOT EXISTS idx_trending_crawled
                ON trending_repos (crawled_at)
            ''')


def save_repos(repos: list[dict], db_path: str = "trending.db") -> str:
    """
    批次存入 repos，回傳 batch_id。
    batch_id 以 ISO datetime 字串表示同一次爬取批次。
    """
    batch_id = datetime.now().strftime("%Y-%m-%dT%H:%M:%S")
    crawled_at = batch_id

    rows = [
        (
            repo.get("author", ""),
            repo.get("repo_name", ""),
            repo.get("full_name", f"{repo.get('author', '')}/{repo.get('repo_name', '')}"),
            repo.get("description"),
            repo.get("language"),
            repo.get("stars_today", 0),
            repo.get("total_stars", 0),
            repo.get("forks", 0),
            repo.get("repo_url", ""),
            crawled_at,
            batch_id,
        )
        for repo in repos
    ]

    with closing(_get_connection(db_path)) as conn:
        with conn:
            conn.executemany('''
                INSERT INTO trending_repos
                    (author, repo_name, full_name, description, language,
                     stars_today, total_stars, forks, repo_url, crawled_at, batch_id)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', rows)

    return batch_id


def get_latest_batch(db_path: str = "trending.db") -> list[dict]:
    """取得最新一批（最新 batch_id）的所有 repos，回傳 list of dict"""
    with closing(_get_connection(db_path)) as conn:
        # 先找出最新的 batch_id
        row = conn.execute('''
            SELECT batch_id FROM trending_repos
            ORDER BY batch_id DESC
            LIMIT 1
        ''').fetchone()

        if row is None:
            return []

        latest_batch_id = row["batch_id"]

        cursor = conn.execute('''
            SELECT id, author, repo_name, full_name, description, language,
                   stars_today, total_stars, forks, repo_url, crawled_at, batch_id
            FROM trending_repos
            WHERE batch_id = ?
            ORDER BY stars_today DESC
        ''', (latest_batch_id,))

        return [dict(r) for r in cursor.fetchall()]


def get_batch_history(db_path: str = "trending.db") -> list[dict]:
    """
    取得所有歷史批次的摘要，回傳 list of dict。
    每項包含 batch_id、該批次 repo 數量、以及爬取時間。
    """
    with closing(_get_connection(db_path)) as conn:
        cursor = conn.execute('''
            SELECT batch_id,
                   COUNT(*)    AS count,
                   MAX(crawled_at) AS crawled_at
            FROM trending_repos
            GROUP BY batch_id
            ORDER BY batch_id DESC
        ''')
        return [dict(r) for r in cursor.fetchall()]


if __name__ == "__main__":
    # 快速驗證：初始化資料庫並顯示路徑
    db_path = os.path.join(os.path.dirname(__file__), "trending.db")
    init_db(db_path)
    print(f"Database initialized at: {db_path}")
