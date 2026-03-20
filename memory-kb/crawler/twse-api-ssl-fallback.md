---
title: twse-api-ssl-fallback
type: note
permalink: multi-agent-system/crawler/twse-api-ssl-fallback
---

# TWSE API SSL Fallback

TWSE API 在 Python 3.13+ 的 SSL 驗證問題與解決方案。

## Problem

- problem_id :: MTA-CRAWLER-002
- title :: TWSE API SSL verification failed on Python 3.13+
- error_message :: SSLCertVerificationError - subject key identifier mismatch
- root_cause :: Python 3.13 加強了 SSL 憑證驗證，TWSE 的憑證 Subject Key Identifier 不符合新標準
- date_solved :: 2026-03-17
- project :: mta_demo2

## Solution

- solution :: 在 stock_crawler.py 實現自動 fallback：先嘗試 verify=True，若 SSL 失敗則自動切換為 verify=False
- prevention :: TWSE 為政府可信來源，verify=False 可接受。未來若 TWSE 更新憑證可移除 fallback

## TWSE API Reference

- api_url :: https://mis.twse.com.tw/stock/api/getStockInfo.jsp
- query_param :: ex_ch=tse_{stock_id}.tw（上市）或 otc_{stock_id}.tw（上櫃）
- response_format :: JSON with msgArray containing stock data

### TWSE Field Mapping
| API 欄位 | 含義 | 對應 DB 欄位 |
|----------|------|-------------|
| c | 股票代號 | stock_id |
| n | 股票名稱 | stock_name |
| z | 當盤成交價 | current_price |
| tv | 當盤成交量 | volume |
| v | 累計成交量 | total_volume |
| o | 開盤價 | open_price |
| h | 最高價 | high_price |
| l | 最低價 | low_price |
| y | 昨收價 | yesterday_close |
| t | 最近成交時刻 | — |

## Relations

- part_of [[Project Overview]]
- relates_to [[TWSE-SSL-001 SSL Verification Failure]]
- used_in [[Stock Data Models]]