---
title: known-issues
type: note
permalink: multi-agent-system/project/known-issues
---

# Known Issues Registry

已解決和未解決問題的集中追蹤。

## PROXY-001 IP Block Issue

- issue_id :: PROXY-001
- title :: Proxy Block Issue
- description :: Website blocked requests from non-residential IPs
- solution :: Use VPN to access, then rotate through residential proxies
- date_solved :: 2026-02-15
- agent_responsible :: Crawler Expert
- status :: SOLVED

## TWSE-SSL-001 SSL Verification Failure

- issue_id :: TWSE-SSL-001
- title :: TWSE API SSL 驗證失敗
- description :: Python 3.13+ 對 TWSE 憑證的 Subject Key Identifier 驗證失敗
- solution :: stock_crawler.py 已實現自動 fallback 為 verify=False（TWSE 為可信來源）
- date_solved :: 2026-03-17
- agent_responsible :: Crawler Expert
- status :: SOLVED

## Relations

- part_of [[Project Overview]]
- resolved_by [[Crawler Expert]]

## STARTUP-PATH-001 mta_demo3 啟動路徑錯誤

- issue_id :: STARTUP-PATH-001
- title :: mta_demo3 啟動時使用錯誤工作目錄導致 ERR_CONNECTION_REFUSED
- description :: 在 workspace root 執行 `py -3 app.py` 會找不到檔案，Flask 未啟動，瀏覽器顯示連線被拒
- solution :: 改用 `py -3 mta_demo3/app.py` 或先 `cd mta_demo3` 再 `py -3 app.py`
- date_solved :: 2026-03-17
- agent_responsible :: Crawler Expert
- status :: SOLVED
