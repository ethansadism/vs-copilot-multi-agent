---
title: mta_demo4_001_us-stock-dashboard-ui
type: note
permalink: multi-agent-system/frontend/mta-demo4-001-us-stock-dashboard-ui
tags:
- app:mta_demo4
- agent:frontend
- experience
---

# mta_demo4 美股即時監聽 Dashboard UI

美股開盤時段即時股價監聽 Dashboard 的前端與 Flask 入口實作。

## Observations

- app :: mta_demo4
- agent :: frontend
- files :: mta_demo4/app.py, mta_demo4/templates/index.html
- port :: 5003
- stack :: Flask + Flask-SocketIO (async_mode=threading) + Vanilla JS
- socketio_client_cdn :: socket.io 4.7.4 (cdnjs)
- theme :: 深色金融風（dark, green/red 漲跌色）
- layout :: CSS Grid 三欄（topbar / sidebar / main / alerts）

## 架構重點

### 目錄鍵值差異修正
`USStockDatabase.get_watchlist()` 回傳 `alert_threshold_pct`，
但 `USStockCrawler.check_alerts()` 期望 watchlist 帶 `threshold` 鍵。
**解法**：app.py 建立 `_get_watchlist_for_crawler()` 做欄位映射：
```python
return [{"symbol": w["symbol"], "threshold": w["alert_threshold_pct"]} for w in db.get_watchlist()]
```

### Redis Graceful Fallback
`USStockCrawler.__init__` 若 Redis 不可達會拋例外。
app.py 以 try/except 包住初始化，失敗時 log warning 仍建立 crawler 物件（無快取模式）。

### SocketIO 雙監聽修正
HTML 中 `price_update` 事件被兩個 `socket.on` 監聽（初始 + 含閃爍版本）。
**正確做法**：只保留含閃爍邏輯的 handler 即可，兩個互不衝突但重複觸發。
（目前兩個都存在，後者覆蓋前者，功能正確，但可精簡）

## REST API 清單

| 路由 | 方法 | 說明 |
|------|------|------|
| `/` | GET | 渲染 index.html |
| `/api/watchlist` | GET | 取得監聽清單 |
| `/api/watchlist` | POST | 新增標的 |
| `/api/watchlist/<symbol>` | DELETE | 移除標的 |
| `/api/watchlist/<symbol>/threshold` | PUT | 更新門檻 |
| `/api/quotes` | GET | 手動觸發 fetch |
| `/api/alerts` | GET | 通知歷史（?limit=N） |
| `/api/market-status` | GET | 美股是否開盤 |

## SocketIO 事件

| 事件 | 方向 | 說明 |
|------|------|------|
| `price_update` | server→client | `{quotes: [...]}` 批次推送 |
| `alert_triggered` | server→client | 單則 alert dict |
| `request_refresh` | client→server | 手動觸發立即抓取 |

## 前端 UI 組成

1. **TopBar** — 標題 + 開盤狀態 badge + Refresh 按鈕
2. **Sidebar** — 新增表單（Symbol + 門檻）+ Watchlist 表格（inline 門檻編輯 + 刪除）
3. **Main** — 股票卡片 Grid（auto-fill minmax 260px），卡片含閃爍動畫
4. **Alerts Panel** — 底部最近 20 則通知 + Toast 通知

## Relations

- relates_to [[mta_demo4_001_us-stock-yfinance-crawler]]
- relates_to [[mta_demo4_001_us-stock-data-models]]
