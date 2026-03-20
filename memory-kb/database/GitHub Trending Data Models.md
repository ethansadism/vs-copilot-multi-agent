---
title: GitHub Trending Data Models
type: note
permalink: multi-agent-system/database/git-hub-trending-data-models
---

# GitHub Trending Data Models

mta_demo3 GitHub Trending 爬蟲的資料模型設計。

## trending_repos Table

- model_name :: trending_repos
- version :: 1.0
- description :: GitHub Trending repos 歷史紀錄表，append-only，以 batch_id 區分批次
- project :: mta_demo3
- db_file :: trending.db
- key_columns :: batch_id (TEXT), crawled_at (TEXT ISO), full_name (TEXT)
- indexes :: idx_trending_batch, idx_trending_language, idx_trending_crawled
- batch_id_format :: "%Y-%m-%dT%H:%M:%S"（字典序 = 時間序，可直接 ORDER BY）

## Function API

- init_db(db_path) :: 建立表和索引，idempotent
- save_repos(repos, db_path) :: executemany 批次寫入，回傳 batch_id
- get_latest_batch(db_path) :: 用 ORDER BY batch_id DESC LIMIT 1 取得最新批次
- get_batch_history(db_path) :: GROUP BY batch_id 取摘要（count + crawled_at）

## Design Patterns

- pattern :: append-only history（不覆蓋，用 batch_id 區分）
- pattern :: WAL mode PRAGMA（同 mta_demo2，支援多讀一寫）
- pattern :: db_path 參數化（呼叫方管理路徑，函式不假設位置）
- pattern :: _get_connection 自動 makedirs（降低呼叫方負擔）
- pattern :: executemany for batch INSERT（原子性 + 效能）

## Relations

- relates_to [[SQLite Patterns]]
- relates_to [[Stock Data Models]]
- relates_to [[Legacy Models]]
