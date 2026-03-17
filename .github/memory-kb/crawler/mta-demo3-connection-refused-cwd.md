---
title: mta-demo3-connection-refused-cwd
type: note
permalink: multi-agent-system/crawler/mta-demo3-connection-refused-cwd
tags:
- crawler
- mta_demo3
- flask
- windows
- connection-refused
---

# mta_demo3 ERR_CONNECTION_REFUSED（啟動目錄錯誤）

## Problem

- problem_id :: CRAWLER-APP-002
- error_message :: can't open file 'C:\\code\\projects\\multi_agent_system\\app.py': [Errno 2] No such file or directory
- root_cause :: 啟動命令在 workspace 根目錄執行 `py -3 app.py`，而非 mta_demo3 目錄，導致 Flask 未啟動，瀏覽器出現 ERR_CONNECTION_REFUSED

## Solution

- solution :: 使用明確路徑 `py -3 mta_demo3/app.py` 或先 `cd mta_demo3` 後執行 `py -3 app.py`
- prevention :: 在 Windows 文件與驗證流程固定使用 `py -3` 並先確認當前工作目錄（`Get-Location`）

## Observations

- python_version :: 3.13.9
- port_check :: 5002 listen success after correct start command
- endpoint_test :: GET / = 200, GET /api/repos = 200

## Relations

- relates_to [[Crawler Best Practices]]
- relates_to [[PowerShell Python Alias Compile Error]]