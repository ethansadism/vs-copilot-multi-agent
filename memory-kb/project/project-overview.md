---
title: project-overview
type: note
permalink: multi-agent-system/project/project-overview
tags:
- project
- overview
---

# Multi-Agent Web Crawler Dashboard

專案總覽與狀態追蹤。

## Observations

- project_name :: Multi-Agent Web Crawler Dashboard
- current_phase :: Active Development
- last_update :: 2026-03-18
- version :: v0.05
- workspace_root :: .github
- database_status :: Ready
- frontend_status :: Ready
- crawler_infrastructure :: Ready
- permissions_system :: Active

## Projects
### mta_demo
- mta_demo_description :: Hacker News Crawler Dashboard
- mta_demo_port :: 8989
- mta_demo_status :: Complete

### mta_demo2
- mta_demo2_description :: 即時台股盤中監看與通知系統
- mta_demo2_port :: 5001
- mta_demo2_status :: Complete
- mta_demo2_tech_stack :: Flask, Flask-SocketIO, APScheduler, SQLite3, Chart.js, TWSE API
- mta_demo2_default_stocks :: 2317 鴻海, 2330 台積電

### mta_demo3
- mta_demo3_description :: GitHub Trending Dashboard
- mta_demo3_port :: 5002
- mta_demo3_status :: Complete
- mta_demo3_tech_stack :: Flask, requests, BeautifulSoup4, SQLite3, Vanilla JS
- mta_demo3_target :: https://github.com/trending

### mta_demo4
- mta_demo4_description :: 美股即時監聽 Dashboard
- mta_demo4_port :: 5003
- mta_demo4_status :: Complete
- mta_demo4_tech_stack :: Flask, Flask-SocketIO, yfinance, Redis, SQLite3, Vanilla JS
- mta_demo4_default_stock :: AAPL (Apple Inc.), threshold 5%
- mta_demo4_db :: data/us_stocks.db
- mta_demo4_redis :: cache TTL 30s + pub/sub (stock_updates, stock_alerts)
- mta_demo4_socketio :: price_update, alert_triggered, request_refresh

## Completed Tasks
- MTA Demo Setup (Crawler + SQLite + Frontend)
- MTA Demo2: 即時台股盤中監看與通知系統
- MTA Demo3: GitHub Trending Dashboard，2026-03-17
- MTA Demo4: 美股即時監聽 Dashboard (yfinance + Redis)，2026-03-18

## Relations

- has_issue [[PROXY-001 IP Block Issue]]
- has_issue [[TWSE-SSL-001 SSL Verification Failure]]
- has_agent [[Crawler Expert]]
- has_agent [[Database Expert]]
- has_agent [[Frontend Engineer]]
