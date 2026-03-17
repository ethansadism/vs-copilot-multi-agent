---
title: powershell-python-alias-compile-error
type: note
permalink: multi-agent-system/crawler/powershell-python-alias-compile-error
tags:
- crawler
- windows
- python
- powershell
- mta_demo3
---

# PowerShell Python Alias Compile Error

## Problem

- problem_id :: CRAWLER-APP-001
- error_message :: python : Python was not found but can be installed from the Microsoft Store
- root_cause :: Windows PowerShell 環境存在 python 命令別名衝突，導致 python -m py_compile 無法穩定呼叫實際 Python 執行器

## Solution

- solution :: 改用 py 啟動器執行語法檢查：py -3 -m py_compile app.py
- prevention :: 在 Windows 專案文件與驗證流程統一使用 py -3；必要時先用 py --version 確認啟動器可用

## Relations

- relates_to [[Crawler Best Practices]]
- relates_to [[GitHub Trending Crawler]]