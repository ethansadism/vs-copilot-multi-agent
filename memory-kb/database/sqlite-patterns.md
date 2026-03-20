---
title: sqlite-patterns
type: note
permalink: multi-agent-system/database/sqlite-patterns
---

# SQLite Patterns

SQLite 使用經驗與最佳實踐。

## Connection Management

- pattern :: SQLite Connection Management
- description :: Use contextlib.closing() to ensure SQLite connections are closed properly when using with statement
- context :: mta_demo/database.py
- date :: 2026-03-17

## Batch Write with Buffer

- pattern :: Batch Write with Buffer
- description :: 使用 deque buffer + threading.Lock + executemany 實現線程安全的批次寫入，適合低頻（每小時）寫入場景
- context :: mta_demo2/database.py
- date :: 2026-03-17

## WAL Mode

- pattern :: SQLite WAL Mode
- description :: 啟用 PRAGMA journal_mode=WAL 允許讀寫並行，適合有 web server 同時讀取的場景
- context :: mta_demo2/database.py
- date :: 2026-03-17

## Migration Experience

- migration_id :: MIG-001
- title :: 首次數據遷移 — 將爬蟲數據從 CSV 導入到數據庫
- date :: 2026-01-15
- challenges :: 數據類型轉換、重複記錄處理
- solution :: 使用 SQLAlchemy ORM 和數據驗證

## Performance Tips

- tip_1 :: 為頻繁查詢的字段創建索引
- tip_2 :: 使用分區表處理大量時間序列數據
- tip_3 :: 實現連接池優化數據庫連接
- tip_4 :: 定期執行 VACUUM 和 ANALYZE 優化查詢

## Backup Strategy

- backup_frequency :: Daily
- backup_retention :: 30 days
- backup_method :: PostgreSQL pg_dump + S3 storage
- recovery_time_objective :: 1 hour

## Relations

- used_by [[Database Expert]]
- relates_to [[Stock Data Models]]
- relates_to [[Legacy Data Models]]