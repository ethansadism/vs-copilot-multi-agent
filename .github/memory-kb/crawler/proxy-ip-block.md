---
title: proxy-ip-block
type: note
permalink: multi-agent-system/crawler/proxy-ip-block
---

# Proxy IP Block Solution

網站封鎖非住宅 IP 的處理經驗。

## Problem

- problem_id :: PROXY-001
- title :: Website blocked requests from non-residential IPs
- error_message :: 403 Forbidden / Connection reset
- root_cause :: 目標網站偵測並封鎖了雲端/資料中心 IP 段
- date_solved :: 2026-02-15

## Solution

- solution :: Use VPN to access, then rotate through residential proxies
- prevention :: 預設使用 residential proxy pool，避免直連

## Best Practices for Proxy Usage

1. 優先使用 residential proxy 而非 datacenter proxy
2. 實現 proxy 輪換機制（每 N 個請求換一個）
3. 失敗時自動切換到下一個 proxy
4. 記錄每個 proxy 的成功率，淘汰低成功率的

## Relations

- part_of [[Known Issues Registry]]
- relates_to [[Crawler Best Practices]]