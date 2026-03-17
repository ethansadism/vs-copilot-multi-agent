"""
台股即時監看系統 — 資料庫模組
使用 SQLite3 進行數據持久化，支援批次寫入（每 1 小時 flush 一次）
"""

import sqlite3
import os
import threading
from datetime import datetime, date
from contextlib import closing
from collections import deque

# 資料庫檔案路徑：mta_demo2/data/stock_data.db
DB_DIR = os.path.join(os.path.dirname(__file__), 'data')
DB_FILE = os.path.join(DB_DIR, 'stock_data.db')

# 預設監看股票清單
DEFAULT_WATCHLIST = [
    ('2317', '鴻海'),
    ('2330', '台積電'),
]


class StockDatabase:
    """台股監看系統的資料庫管理類別"""

    def __init__(self, db_path=None):
        self._db_path = db_path or DB_FILE
        self._lock = threading.Lock()        # 保護寫入操作的線程鎖
        self._buffer = deque()               # 股價數據暫存 buffer

        # 自動建立 data 目錄
        db_dir = os.path.dirname(self._db_path)
        if db_dir:
            os.makedirs(db_dir, exist_ok=True)

        # 初始化資料庫
        self._init_db()

    # ------------------------------------------------------------------
    # 連線與初始化
    # ------------------------------------------------------------------

    def _get_connection(self):
        """取得 SQLite 連線，啟用 WAL 模式與外鍵約束"""
        conn = sqlite3.connect(self._db_path)
        conn.row_factory = sqlite3.Row
        conn.execute("PRAGMA journal_mode=WAL")
        conn.execute("PRAGMA foreign_keys=ON")
        return conn

    def _init_db(self):
        """建立資料表並插入預設監看清單"""
        with closing(self._get_connection()) as conn:
            with conn:
                # 股價歷史紀錄
                conn.execute('''
                    CREATE TABLE IF NOT EXISTS stock_prices (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        stock_id TEXT NOT NULL,
                        stock_name TEXT,
                        current_price REAL,
                        change_amount REAL,
                        change_percent REAL,
                        volume INTEGER,
                        open_price REAL,
                        high_price REAL,
                        low_price REAL,
                        yesterday_close REAL,
                        recorded_at TEXT NOT NULL,
                        saved_at TEXT NOT NULL
                    )
                ''')

                # 監看清單
                conn.execute('''
                    CREATE TABLE IF NOT EXISTS stock_watchlist (
                        stock_id TEXT PRIMARY KEY,
                        stock_name TEXT,
                        added_at TEXT NOT NULL
                    )
                ''')

                # 通知紀錄
                conn.execute('''
                    CREATE TABLE IF NOT EXISTS alerts (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        stock_id TEXT NOT NULL,
                        stock_name TEXT,
                        alert_type TEXT NOT NULL,
                        message TEXT,
                        trigger_value REAL,
                        created_at TEXT NOT NULL
                    )
                ''')

                # 為常用查詢建立索引
                conn.execute('''
                    CREATE INDEX IF NOT EXISTS idx_prices_stock_recorded
                    ON stock_prices (stock_id, recorded_at)
                ''')
                conn.execute('''
                    CREATE INDEX IF NOT EXISTS idx_alerts_created
                    ON alerts (created_at DESC)
                ''')

            # 插入預設監看股票（若不存在）
            with conn:
                now = datetime.now().isoformat()
                for stock_id, stock_name in DEFAULT_WATCHLIST:
                    conn.execute(
                        'INSERT OR IGNORE INTO stock_watchlist (stock_id, stock_name, added_at) '
                        'VALUES (?, ?, ?)',
                        (stock_id, stock_name, now),
                    )

    # ------------------------------------------------------------------
    # 批次寫入機制
    # ------------------------------------------------------------------

    def buffer_price_data(self, data_list):
        """
        將股價數據暫存到記憶體 buffer（線程安全）

        data_list: list[dict]，每筆 dict 至少包含 stock_id 和 recorded_at，
                   其餘欄位為選填。
        """
        with self._lock:
            self._buffer.extend(data_list)

    def flush_to_db(self):
        """
        將 buffer 中的數據一次性批次寫入 SQLite（線程安全）
        回傳寫入筆數。
        """
        # 先把 buffer 中的數據取出，盡快釋放鎖
        with self._lock:
            if not self._buffer:
                return 0
            batch = list(self._buffer)
            self._buffer.clear()

        saved_at = datetime.now().isoformat()
        rows = []
        for d in batch:
            rows.append((
                d.get('stock_id'),
                d.get('stock_name'),
                d.get('current_price'),
                d.get('change_amount'),
                d.get('change_percent'),
                d.get('volume'),
                d.get('open_price'),
                d.get('high_price'),
                d.get('low_price'),
                d.get('yesterday_close'),
                d.get('recorded_at', saved_at),
                saved_at,
            ))

        insert_sql = '''
            INSERT INTO stock_prices
                (stock_id, stock_name, current_price, change_amount, change_percent,
                 volume, open_price, high_price, low_price, yesterday_close,
                 recorded_at, saved_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        '''

        with closing(self._get_connection()) as conn:
            with conn:
                conn.executemany(insert_sql, rows)

        return len(rows)

    def get_buffer_size(self):
        """取得目前 buffer 中的待寫入筆數"""
        with self._lock:
            return len(self._buffer)

    # ------------------------------------------------------------------
    # 股價查詢
    # ------------------------------------------------------------------

    def get_today_prices(self, stock_id):
        """取得今日某股票的所有歷史價格紀錄"""
        today_str = date.today().isoformat()  # 'YYYY-MM-DD'
        sql = '''
            SELECT * FROM stock_prices
            WHERE stock_id = ? AND recorded_at >= ?
            ORDER BY recorded_at ASC
        '''
        with closing(self._get_connection()) as conn:
            cursor = conn.execute(sql, (stock_id, today_str))
            return [dict(row) for row in cursor.fetchall()]

    # ------------------------------------------------------------------
    # 監看清單
    # ------------------------------------------------------------------

    def get_watchlist(self):
        """取得監看清單"""
        sql = 'SELECT * FROM stock_watchlist ORDER BY added_at ASC'
        with closing(self._get_connection()) as conn:
            cursor = conn.execute(sql)
            return [dict(row) for row in cursor.fetchall()]

    def add_to_watchlist(self, stock_id, stock_name):
        """加入監看清單（若已存在則忽略）"""
        sql = '''
            INSERT OR IGNORE INTO stock_watchlist (stock_id, stock_name, added_at)
            VALUES (?, ?, ?)
        '''
        with closing(self._get_connection()) as conn:
            with conn:
                conn.execute(sql, (stock_id, stock_name, datetime.now().isoformat()))

    def remove_from_watchlist(self, stock_id):
        """從監看清單移除"""
        sql = 'DELETE FROM stock_watchlist WHERE stock_id = ?'
        with closing(self._get_connection()) as conn:
            with conn:
                conn.execute(sql, (stock_id,))

    # ------------------------------------------------------------------
    # 通知紀錄
    # ------------------------------------------------------------------

    def get_recent_alerts(self, limit=20):
        """取得最近的通知紀錄"""
        sql = '''
            SELECT * FROM alerts
            ORDER BY created_at DESC
            LIMIT ?
        '''
        with closing(self._get_connection()) as conn:
            cursor = conn.execute(sql, (limit,))
            return [dict(row) for row in cursor.fetchall()]

    def save_alert(self, stock_id, stock_name, alert_type, message, trigger_value):
        """儲存一筆通知紀錄"""
        sql = '''
            INSERT INTO alerts (stock_id, stock_name, alert_type, message, trigger_value, created_at)
            VALUES (?, ?, ?, ?, ?, ?)
        '''
        with closing(self._get_connection()) as conn:
            with conn:
                conn.execute(sql, (
                    stock_id, stock_name, alert_type,
                    message, trigger_value,
                    datetime.now().isoformat(),
                ))


# 方便直接執行測試
if __name__ == '__main__':
    db = StockDatabase()
    print(f'資料庫已初始化：{db._db_path}')
    print(f'監看清單：{db.get_watchlist()}')

    # 測試 buffer → flush
    test_data = [
        {
            'stock_id': '2330',
            'stock_name': '台積電',
            'current_price': 890.0,
            'change_amount': 15.0,
            'change_percent': 1.71,
            'volume': 32000,
            'open_price': 878.0,
            'high_price': 895.0,
            'low_price': 876.0,
            'yesterday_close': 875.0,
            'recorded_at': datetime.now().isoformat(),
        },
    ]
    db.buffer_price_data(test_data)
    count = db.flush_to_db()
    print(f'已寫入 {count} 筆股價數據')
    print(f'今日 2330 價格：{db.get_today_prices("2330")}')
