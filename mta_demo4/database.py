"""
美股即時監聽系統 — 資料庫模組
使用 SQLite3 進行數據持久化，管理監聽清單、歷史報價與通知紀錄
"""

import sqlite3
import os
import threading
from datetime import datetime
from contextlib import closing

# 資料庫檔案路徑：mta_demo4/data/us_stocks.db
DB_DIR = os.path.join(os.path.dirname(__file__), 'data')


class USStockDatabase:
    """美股即時監聽系統的資料庫管理類別"""

    def __init__(self, db_name='us_stocks.db'):
        self._db_path = os.path.join(DB_DIR, db_name)
        self._lock = threading.Lock()

        os.makedirs(DB_DIR, exist_ok=True)
        self._init_db()

    # ------------------------------------------------------------------
    # 連線與初始化
    # ------------------------------------------------------------------

    def _get_connection(self):
        """取得 SQLite 連線，啟用 WAL 模式"""
        conn = sqlite3.connect(self._db_path)
        conn.row_factory = sqlite3.Row
        conn.execute("PRAGMA journal_mode=WAL")
        conn.execute("PRAGMA foreign_keys=ON")
        return conn

    def _init_db(self):
        """建立資料表、索引，並插入預設監聽股票（若清單為空）"""
        with closing(self._get_connection()) as conn:
            with conn:
                # 監聽清單（含門檻設定）
                conn.execute('''
                    CREATE TABLE IF NOT EXISTS watchlist (
                        symbol TEXT PRIMARY KEY,
                        name TEXT,
                        alert_threshold_pct REAL DEFAULT 5.0,
                        added_at TEXT NOT NULL
                    )
                ''')

                # 歷史報價
                conn.execute('''
                    CREATE TABLE IF NOT EXISTS stock_prices (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        symbol TEXT NOT NULL,
                        name TEXT,
                        price REAL,
                        change_amount REAL,
                        change_percent REAL,
                        volume INTEGER,
                        prev_close REAL,
                        market_cap REAL,
                        recorded_at TEXT NOT NULL
                    )
                ''')

                # 通知紀錄
                conn.execute('''
                    CREATE TABLE IF NOT EXISTS alerts (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        symbol TEXT NOT NULL,
                        name TEXT,
                        alert_type TEXT NOT NULL,
                        message TEXT,
                        trigger_value REAL,
                        threshold REAL,
                        created_at TEXT NOT NULL
                    )
                ''')

                # 索引
                conn.execute('''
                    CREATE INDEX IF NOT EXISTS idx_prices_symbol_recorded
                    ON stock_prices (symbol, recorded_at)
                ''')
                conn.execute('''
                    CREATE INDEX IF NOT EXISTS idx_alerts_created
                    ON alerts (created_at DESC)
                ''')

            # 若 watchlist 為空，插入預設值
            with conn:
                row = conn.execute('SELECT COUNT(*) FROM watchlist').fetchone()
                if row[0] == 0:
                    now = datetime.now().isoformat()
                    conn.execute(
                        'INSERT INTO watchlist (symbol, name, alert_threshold_pct, added_at) '
                        'VALUES (?, ?, ?, ?)',
                        ('AAPL', 'Apple Inc.', 5.0, now),
                    )

    # ------------------------------------------------------------------
    # 監聽清單管理
    # ------------------------------------------------------------------

    def add_to_watchlist(self, symbol: str, name: str, threshold_pct: float = 5.0):
        """新增股票到監聽清單；若已存在則更新名稱與門檻"""
        now = datetime.now().isoformat()
        with closing(self._get_connection()) as conn:
            with conn:
                conn.execute(
                    '''
                    INSERT INTO watchlist (symbol, name, alert_threshold_pct, added_at)
                    VALUES (?, ?, ?, ?)
                    ON CONFLICT(symbol) DO UPDATE SET
                        name = excluded.name,
                        alert_threshold_pct = excluded.alert_threshold_pct
                    ''',
                    (symbol.upper(), name, threshold_pct, now),
                )

    def remove_from_watchlist(self, symbol: str):
        """從監聽清單移除指定股票"""
        with closing(self._get_connection()) as conn:
            with conn:
                conn.execute(
                    'DELETE FROM watchlist WHERE symbol = ?',
                    (symbol.upper(),),
                )

    def update_threshold(self, symbol: str, threshold_pct: float):
        """更新指定股票的通知門檻（%）"""
        with closing(self._get_connection()) as conn:
            with conn:
                conn.execute(
                    'UPDATE watchlist SET alert_threshold_pct = ? WHERE symbol = ?',
                    (threshold_pct, symbol.upper()),
                )

    def get_watchlist(self) -> list[dict]:
        """取得完整監聽清單"""
        with closing(self._get_connection()) as conn:
            cursor = conn.execute(
                'SELECT symbol, name, alert_threshold_pct, added_at '
                'FROM watchlist ORDER BY added_at ASC'
            )
            return [dict(row) for row in cursor.fetchall()]

    # ------------------------------------------------------------------
    # 股價資料
    # ------------------------------------------------------------------

    def save_prices(self, prices_list: list[dict]):
        """
        批次寫入股價紀錄（線程安全）

        prices_list: list[dict]，每筆 dict 包含 symbol, name, price,
                     change_amount, change_percent, volume, prev_close,
                     market_cap, recorded_at（選填，預設為當下時間）
        """
        if not prices_list:
            return

        now = datetime.now().isoformat()
        rows = [
            (
                d.get('symbol', '').upper(),
                d.get('name'),
                d.get('price'),
                d.get('change_amount'),
                d.get('change_percent'),
                d.get('volume'),
                d.get('prev_close'),
                d.get('market_cap'),
                d.get('recorded_at', now),
            )
            for d in prices_list
        ]

        insert_sql = '''
            INSERT INTO stock_prices
                (symbol, name, price, change_amount, change_percent,
                 volume, prev_close, market_cap, recorded_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        '''

        with self._lock:
            with closing(self._get_connection()) as conn:
                with conn:
                    conn.executemany(insert_sql, rows)

    def get_latest_prices(self) -> list[dict]:
        """取得每個監聽股票的最新一筆報價"""
        sql = '''
            SELECT sp.*
            FROM stock_prices sp
            INNER JOIN (
                SELECT symbol, MAX(recorded_at) AS latest
                FROM stock_prices
                GROUP BY symbol
            ) latest_map
            ON sp.symbol = latest_map.symbol
            AND sp.recorded_at = latest_map.latest
            ORDER BY sp.symbol ASC
        '''
        with closing(self._get_connection()) as conn:
            cursor = conn.execute(sql)
            return [dict(row) for row in cursor.fetchall()]

    # ------------------------------------------------------------------
    # 通知紀錄
    # ------------------------------------------------------------------

    def save_alert(
        self,
        symbol: str,
        name: str,
        alert_type: str,
        message: str,
        trigger_value: float,
        threshold: float,
    ):
        """寫入一筆通知紀錄"""
        now = datetime.now().isoformat()
        with closing(self._get_connection()) as conn:
            with conn:
                conn.execute(
                    '''
                    INSERT INTO alerts
                        (symbol, name, alert_type, message, trigger_value, threshold, created_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                    ''',
                    (symbol.upper(), name, alert_type, message, trigger_value, threshold, now),
                )

    def get_alerts(self, limit: int = 50) -> list[dict]:
        """取得最近 N 筆通知紀錄（由新到舊）"""
        with closing(self._get_connection()) as conn:
            cursor = conn.execute(
                'SELECT * FROM alerts ORDER BY created_at DESC LIMIT ?',
                (limit,),
            )
            return [dict(row) for row in cursor.fetchall()]

    # ------------------------------------------------------------------
    # 資源管理
    # ------------------------------------------------------------------

    def close(self):
        """釋放資源（目前使用 closing context manager，此方法為 API 相容保留）"""
        pass
