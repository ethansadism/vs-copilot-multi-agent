---
title: mta_demo4_001_us-stock-data-models
type: note
permalink: multi-agent-system/database/mta-demo4-001-us-stock-data-models
tags:
- app:mta_demo4
- agent:database
- experience
---

# mta_demo4 美股即時監聽系統資料模型

美股開盤時段即時股價監聽 Dashboard 的 SQLite 資料庫設計。

## Observations

- app :: mta_demo4
- agent :: database
- db_file :: mta_demo4/data/us_stocks.db
- orm :: SQLite3 (class wrapper, WAL mode)
- pattern :: 參考 mta_demo2 StockDatabase，移除批次 buffer，改為直接批次 INSERT

## Schema 設計

### watchlist 表
監聽清單與通知門檻合一設計（避免 JOIN）：
- `symbol` TEXT PK
- `name` TEXT
- `alert_threshold_pct` REAL DEFAULT 5.0（漲跌幅通知門檻 %）
- `added_at` TEXT NOT NULL
- 預設值：AAPL, Apple Inc., 5.0

### stock_prices 表
歷史報價（每次輪詢寫入）：
- `id` INTEGER PK AUTOINCREMENT
- `symbol`, `name`, `price`, `change_amount`, `change_percent`
- `volume`, `prev_close`, `market_cap`, `recorded_at`
- INDEX: (symbol, recorded_at)

### alerts 表
通知觸發紀錄：
- `id` INTEGER PK AUTOINCREMENT
- `symbol`, `name`, `alert_type`, `message`
- `trigger_value`（觸發時的漲跌幅）、`threshold`（當時門檻）
- `created_at`
- INDEX: (created_at DESC)

## 主要方法

| 方法 | 說明 |
|------|------|
| `add_to_watchlist(symbol, name, threshold_pct=5.0)` | INSERT OR UPDATE |
| `remove_from_watchlist(symbol)` | 移除 |
| `update_threshold(symbol, threshold_pct)` | 更新門檻 |
| `get_watchlist()` | 回傳 list[dict] |
| `save_prices(prices_list)` | 批次 INSERT，線程安全 |
| `get_latest_prices()` | 每個 symbol 最新一筆（子查詢 MAX） |
| `save_alert(...)` | 寫入通知紀錄 |
| `get_alerts(limit=50)` | 回傳最近 N 筆 |
| `close()` | API 相容保留 |

## 設計決策

- watchlist 與 threshold 合一表，避免跨表查詢，簡化前端 API
- `save_prices` 使用 `threading.Lock` 保護批次寫入
- `get_latest_prices` 用子查詢 MAX(recorded_at) 取最新一筆，避免 ROW_NUMBER（SQLite 相容）
- `add_to_watchlist` 使用 `INSERT OR CONFLICT DO UPDATE`，支援 upsert
- `symbol` 統一 `.upper()` 正規化，避免大小寫不一致

## Relations

- relates_to [[mta_demo2_001_stock-data-models]]
