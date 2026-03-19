---
title: Development Session 2026-03-17
type: note
permalink: multi-agent-system/project/development-session-2026-03-17
tags:
- session
- changelog
- v0.02
---

# Development Session 2026-03-17

本次會話完成了系統架構審計後的 P0-P2 優化，並解釋了 Layer 1 專案隔離機制。

## Observations

- session_date :: 2026-03-17
- version :: v0.031
- commit :: c5ea59c on mcp-basic-memory
- tag :: v0.031
- action_P0 :: 刪除 .github/memory/ (5 legacy JSON) + .github/tools/ (TOOLS_MANIFEST + mcp-registry)，共 -901 行
- action_P1_hooks :: subagent-start.ps1/.sh 移除重複的「必做事項」+「筆記格式」，每次 subagent 啟動省 ~300 tokens
- action_P1_reports :: 3 個 subagent agent.md step 5 從「寫 .github/reports/」改為「1 行摘要 + memory-kb permalink」
- action_P1_pm :: PM agent step 5 改為用 read_note(permalink) 取代檢查 reports 目錄
- action_P2_app_tag :: PM 調用 subagent 時傳遞目標 app 名稱；subagent 筆記加 app :: xxx 標籤
- action_P2_search :: PM search workflow 加入 search_notes("app :: mta_demoX") 按 app 篩選
- layer1_explained :: Basic Memory 專案隔離靠 .vscode/mcp.json 的 --project flag，建立獨立 SQLite 索引於 ~/basic-memory/<project-name>/memory.db
- files_deleted :: .github/memory/crawler-memory.json, database-memory.json, frontend-memory.json, project-state.json, session-.json, .github/tools/TOOLS_MANIFEST.md, mcp-registry.json
- files_modified :: subagent-start.ps1, subagent-start.sh, crawler.agent.md, database.agent.md, frontend.agent.md, pm.agent.md

## Context

前次會話（v0.03）完成了：
1. mta_demo3 (GitHub Trending Dashboard) 建立
2. ERR_CONNECTION_REFUSED 診斷與修復
3. 完整系統架構審計（4 個問題：記憶注入垃圾、token 浪費、tools 使用率、可攜性）

本次會話接續執行審計後的優化建議：
- P0: 刪除零使用的遺留檔案（.github/memory/ 和 .github/tools/）
- P1: 精簡 SubagentStart hook 移除與 agent.md 重複的內容；報告機制從實體檔案改為 permalink
- P2: 為 PM 加入 app-aware 搜尋和 subagent 筆記 app 標籤

Layer 1 隔離機制解釋：
- 唯一隔離鍵是 .vscode/mcp.json 的 `--project "multi-agent-system"` 參數
- Basic Memory MCP server 啟動時用此參數建立獨立 SQLite 索引
- 所有 search_notes/write_note/read_note 呼叫自動 scope 到該 project
- Markdown 檔案在 repo (.github/memory-kb/)，索引在本地 (~/)，clone 後首次啟動自動重建

## Relations

- follows [[Project Overview]]
- follows [[Known Issues]]
- updates [[project/project-overview]]
