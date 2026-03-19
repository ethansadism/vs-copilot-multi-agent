---
title: js-rendering
type: note
permalink: multi-agent-system/crawler/js-rendering
---

# JavaScript Rendering Solution

需要 JS 渲染的頁面爬蟲方案。

## Problem

- problem_id :: JS-RENDER-001
- title :: Pages require JavaScript rendering
- root_cause :: SPA 或動態載入內容無法用純 requests 抓取

## Solution

- solution :: 使用 Playwright 或 Selenium 進行 headless browser 渲染
- prevention :: 先檢查頁面是否為 SPA，是的話直接使用 Playwright

## Tool Comparison

| 工具 | 優點 | 缺點 |
|------|------|------|
| Playwright | 速度快、API 現代化 | 需安裝 browser |
| Selenium | 社群大、資源多 | 速度較慢 |
| requests-html | 輕量、簡單 | 功能有限 |

## Relations

- relates_to [[Crawler Best Practices]]