---
title: project-overview
type: note
permalink: multi-agent-system/project/project-overview
---

# Multi-Agent Web Crawler Dashboard

專案總覽與狀態追蹤。

## Observations

- project_name :: Multi-Agent Web Crawler Dashboard
- current_phase :: Active Development
- last_update :: 2026-03-17
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
- mta_demo2_files :: app.py, stock_crawler.py, database.py, templates/index.html, requirements.txt

### mta_demo3
- mta_demo3_description :: GitHub Trending Dashboard
- mta_demo3_port :: 5002
- mta_demo3_status :: Complete
- mta_demo3_tech_stack :: Flask, requests, BeautifulSoup4, SQLite3, Vanilla JS
- mta_demo3_target :: https://github.com/trending
- mta_demo3_files :: app.py, github_crawler.py, database.py, templates/index.html, requirements.txt
- mta_demo3_db :: trending.db（append-only，保留歷史批次）
- mta_demo3_routes :: GET /, POST /refresh, GET /api/repos

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
- mta_demo2_files :: app.py, stock_crawler.py, database.py, templates/index.html, requirements.txt

## Completed Tasks
- MTA Demo Setup (Crawler + SQLite + Frontend)
- MTA Demo2: 即時台股盤中監看與通知系統 (Crawler + SQLite + Flask-SocketIO + Frontend)
- MTA Demo3: GitHub Trending Dashboard (Crawler + SQLite + Frontend)，2026-03-17

## Relations

- has_issue [[PROXY-001 IP Block Issue]]
- has_issue [[TWSE-SSL-001 SSL Verification Failure]]
- has_agent [[Crawler Expert]]
- has_agent [[Database Expert]]
- has_agent [[Frontend Engineer]]

## Runtime Notes 2026-03-17

- mta_demo3_connection_refused_root_cause :: app 未啟動（常見為在 workspace root 直接執行 `py -3 app.py` 導致找不到檔案）
- mta_demo3_start_command_root :: py -3 mta_demo3/app.py
- mta_demo3_start_command_project :: cd mta_demo3 && py -3 app.py
- mta_demo3_healthcheck :: GET / and GET /api/repos both return 200 when service is running
