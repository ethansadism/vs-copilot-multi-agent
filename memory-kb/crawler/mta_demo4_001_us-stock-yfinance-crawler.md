---
title: mta_demo4_001_us-stock-yfinance-crawler
type: note
permalink: multi-agent-system/crawler/mta-demo4-001-us-stock-yfinance-crawler
tags:
- app:mta_demo4
- agent:crawler
- experience
---

# mta_demo4 美股即時報價爬蟲實作

美股 Dashboard (mta_demo4) 的爬蟲核心，使用 yfinance + Redis 快取 + Pub/Sub。

## Observations

- app :: mta_demo4
- agent :: crawler
- file :: mta_demo4/stock_crawler.py
- data_source :: yfinance
- cache_backend :: Redis (TTL 30s, key: stock:{SYMBOL})
- pubsub_channels :: stock_updates, stock_alerts
- market_timezone :: America/New_York (zoneinfo)
- market_hours :: 09:30–16:00 ET, Mon–Fri

## 實作重點

### change_percent 計算方式
yfinance `info['regularMarketChangePercent']` 在不同版本單位不一致（有時是小數 0.026，有時是百分比 2.6）。  
**解法**：改為自行計算 `(price - prev_close) / prev_close * 100`，完全可靠。

### yfinance rate limit 防護
- Redis cache TTL 30s 是主要保護機制（cache hit 不呼叫 yfinance）
- 批次查詢時每個 symbol 間加 0.2s 延遲（`time.sleep(0.2)`）
- `yf.Ticker(symbol).info` 為逐一請求，無真正批次 API

### 交易時段判斷
使用 `zoneinfo.ZoneInfo("America/New_York")` 處理 DST，Python < 3.9 用 `backports.zoneinfo`。  
非交易時段不啟動自動輪詢，但 `fetch_quotes` 仍可手動呼叫。

### 類別設計
```
USStockCrawler
├── fetch_quotes(symbols)      ← cache-first 多 symbol 查詢
├── check_alerts(quotes, watchlist) ← 比對門檻，Pub/Sub 發布
├── is_market_open()           ← ET 時區判斷
├── start_polling(...)         ← daemon thread，自動跳過非交易時段
└── stop_polling()             ← join(timeout=5)
```

### Redis 設計
| key/channel | 用途 | TTL |
|---|---|---|
| `stock:{SYMBOL}` | 報價快取 | 30s |
| `stock_updates` | Pub/Sub 新報價 | — |
| `stock_alerts` | Pub/Sub 警報 | — |

## Relations

- relates_to [[general_001_best-practices]]
