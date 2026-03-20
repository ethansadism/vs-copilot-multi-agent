---
title: stock-monitoring-ui
type: note
permalink: multi-agent-system/frontend/stock-monitoring-ui
---

# Stock Monitoring UI

mta_demo2 台股即時監看的前端實現。

## Features

- framework :: Flask + Flask-SocketIO (port 5001)
- realtime :: WebSocket 即時股價推送 (stock_update / alert events)
- rest_api :: /api/watchlist, /api/alerts, /api/history/<stock_id>
- charting :: Chart.js 4.x 即時走勢線圖
- scheduler :: APScheduler 每 1 小時 flush_to_db
- theme :: 深色主題 (#1a1a2e) + 台股紅漲綠跌配色
- layout :: 響應式設計 (CSS Grid + Flexbox)

## Charts

### CHART-001
- chart_name :: Website Data Distribution
- chart_type :: Bar Chart
- library :: Chart.js
- data_source :: WebsiteData table
- date :: 2026-02-01

### CHART-002
- chart_name :: Crawl Timeline
- chart_type :: Line Chart
- library :: Chart.js
- date :: 2026-02-05

### CHART-003
- chart_name :: 台股即時走勢圖
- chart_type :: Line Chart (Realtime)
- library :: Chart.js 4.x
- data_source :: WebSocket stock_update events
- date :: 2026-03-17
- max_data_points :: 100（可切換不同股票）

## Recent Improvements

- 實現暗黑模式支持
- 優化移動設備響應式設計
- 添加數據實時刷新功能
- mta_demo2: 建立台股即時監看 UI (Socket.IO + Chart.js)
- mta_demo2: WebSocket 即時推送取代 polling
- mta_demo2: 台股紅漲綠跌配色方案

## Relations

- part_of [[Project Overview]]
- uses [[Dashboard Design System]]
- data_from [[Stock Data Models]]