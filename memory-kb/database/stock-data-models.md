---
title: stock-data-models
type: note
permalink: multi-agent-system/database/stock-data-models
---

# Stock Data Models

mta_demo2 台股即時監看系統的資料模型設計。

## StockPrices Table

- model_name :: StockPrices
- version :: 1.0
- description :: 台股即時監看系統 — 股價歷史紀錄表，搭配 buffer + flush 批次寫入
- project :: mta_demo2

### Fields
| 欄位 | 類型 | 說明 |
|------|------|------|
| id | INTEGER PK | 主鍵 |
| stock_id | TEXT NOT NULL | 股票代號 |
| stock_name | TEXT | 股票名稱 |
| current_price | REAL | 當前價格 |
| change_amount | REAL | 漲跌金額 |
| change_percent | REAL | 漲跌幅 |
| volume | INTEGER | 成交量 |
| open_price | REAL | 開盤價 |
| high_price | REAL | 最高價 |
| low_price | REAL | 最低價 |
| yesterday_close | REAL | 昨收價 |
| recorded_at | TEXT NOT NULL | 紀錄時間 |
| saved_at | TEXT NOT NULL | 儲存時間 |

- index :: (stock_id, recorded_at)

## StockWatchlist Table

- model_name :: StockWatchlist
- version :: 1.0
- description :: 台股監看清單，stock_id 為 PK
- project :: mta_demo2

### Fields
| 欄位 | 類型 | 說明 |
|------|------|------|
| stock_id | TEXT PK | 股票代號（主鍵）|
| stock_name | TEXT | 股票名稱 |
| added_at | TEXT NOT NULL | 加入時間 |

## Alerts Table

- model_name :: Alerts
- version :: 1.0
- description :: 台股通知紀錄表
- project :: mta_demo2

### Fields
| 欄位 | 類型 | 說明 |
|------|------|------|
| id | INTEGER PK | 主鍵 |
| stock_id | TEXT NOT NULL | 股票代號 |
| stock_name | TEXT | 股票名稱 |
| alert_type | TEXT NOT NULL | 通知類型 |
| message | TEXT | 通知內容 |
| trigger_value | REAL | 觸發值 |
| created_at | TEXT NOT NULL | 建立時間 |

- index :: (created_at DESC)

## Relations

- part_of [[Project Overview]]
- used_by [[Frontend Engineer]]
- data_from [[TWSE API SSL Fallback]]