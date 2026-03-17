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

## Completed Tasks

- MTA Demo Setup (Crawler + SQLite + Frontend)
- MTA Demo2: 即時台股盤中監看與通知系統 (Crawler + SQLite + Flask-SocketIO + Frontend)

## Relations

- has_issue [[PROXY-001 IP Block Issue]]
- has_issue [[TWSE-SSL-001 SSL Verification Failure]]
- has_agent [[Crawler Expert]]
- has_agent [[Database Expert]]
- has_agent [[Frontend Engineer]]