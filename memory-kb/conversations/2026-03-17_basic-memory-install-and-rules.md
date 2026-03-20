---
title: 2026-03-17_basic-memory-install-and-rules
type: note
permalink: multi-agent-system/conversations/2026-03-17-basic-memory-install-and-rules
tags:
- session
- agent:claude
- '2026-03-17'
---

# 會話紀錄：Basic Memory 安裝與記憶規範建立

## Observations

- session_date :: 2026-03-17
- version :: v0.04
- agent :: claude
- machine :: macOS (Dennis 換機後首次)

## 完成的事

### 1. Basic Memory MCP 安裝
- installed :: uv 0.10.11 + basic-memory 0.20.2（via `curl -LsSf https://astral.sh/uv/install.sh | sh`）
- uvx_path :: /Users/DennisKao/.local/bin/uvx
- project_registered :: multi-agent-system → ~/.github/memory-kb/
- index_status :: 20 entities, 54 relations, 561 chunks
- mcp_json_fix :: .vscode/mcp.json 的 command 從 `uvx` 改為完整路徑 `/Users/DennisKao/.local/bin/uvx`（VS Code 不繼承 shell PATH）

### 2. Basic Memory 功能實測
- nested_folders :: 支援任意深度，write_note directory="crawler/mta_demo3" 可建立子資料夾，list_directory 可讀到
- filename_rule :: title 參數直接對應磁碟檔名，title 寫什麼就是什麼
- tags_filter :: search_notes 的 tags 參數可精確布林篩選，實測 tags=["test"] 只回傳 1 筆（有效隔離）
- delete_note :: 刪除索引 + 磁碟檔案，但保留空目錄（需手動 rmdir）
- conversations_folder :: 可新增，write_note directory="conversations" 正常運作

### 3. 規則修改
- copilot_instructions :: 新建 .github/copilot-instructions.md（全域生效，所有對話視窗自動載入）
- naming_rule :: title 格式改為 {app-id}_{seq}_{name}，例如 mta_demo3_001_github-trending-crawler
- tag_rule :: write_note 必填 tags: ["app:mta_demo3", "agent:crawler", "experience"]
- search_rule :: 精確搜尋用 search_notes("關鍵字", tags=["app:mta_demo3"])
- files_modified :: crawler.agent.md, database.agent.md, frontend.agent.md, pm.agent.md（命名規範 + tag 規範）
- pm_updated :: conversations/ 加入資料夾結構；Step 6 加入對話摘要寫法；調用 subagent 指示更新命名要求
- gap001_status :: IMPLEMENTING（memory-system-gaps.md 已更新）

## 待辦（下次繼續）

- todo_1 :: 舊筆記未補 app tag（低優先，demo 資料）
- todo_2 :: GAP-002（agent 搜尋品質）、GAP-003（強制記憶）、GAP-004（跨專案隔離實測）仍 open
- todo_3 :: README.md / ARCHITECTURE.md 版本號仍是 v0.02，未更新

## Relations

- updates [[project-overview]]
- follows [[Development Session 2026-03-17]]
- fixes [[memory-system-gaps]]
