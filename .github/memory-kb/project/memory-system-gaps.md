---
title: Memory System Gaps Analysis
type: note
permalink: multi-agent-system/project/memory-system-gaps
tags:
- architecture
- memory
- gaps
- v0.02
---

# Memory System Gaps Analysis

v0.02 Basic Memory 整合後，仍存在的架構缺陷和待解決問題。

## Observations

- analysis_date :: 2026-03-17
- version :: v0.02
- severity :: MEDIUM — hooks 已修復、tools 已修正，剩餘 GAP-001~004 等待實測驗證

## 未解決問題

### GAP-001 同專案多 App 記憶混淆

- gap_id :: GAP-001
- description :: search_notes 搜全專案，無法限定 folder。搜 "SQLite model" 會同時回傳 mta_demo 和 mta_demo2 的結果
- impact :: agent 可能套用錯誤 app 的經驗
- proposed_solution :: 在筆記的 Observations 中加入 app tag（如 `app :: mta_demo2`），搜尋時包含 app 名稱；或未來 Basic Memory 支援 folder filter

### GAP-002 Agent 查詢品質無法保證

- gap_id :: GAP-002
- description :: LLM 產生的 search query 品質不穩定，可能搜到不相關記憶
- impact :: 記憶污染仍可能發生
- proposed_solution :: 在 agent 指令中提供搜尋範例和最佳實踐；PM 預先搜尋再傳給 subagent

### GAP-003 無法技術性強制記憶讀寫

- gap_id :: GAP-003
- description :: agent 指令寫「強制」但 MCP 不能被 hook 強制呼叫。agent 可能跳過 search_notes 或 write_note
- impact :: 記憶可能不被更新，經驗流失
- proposed_solution :: SubagentStop hook 檢查 memory-kb/{folder}/ 檔案修改時間，未更新則注入強烈警告；結合 agent 指令「未更新記憶 = 任務未完成」形成雙重保障

### GAP-004 跨專案隔離未實測

- gap_id :: GAP-004
- description :: Basic Memory multi-project 功能存在但目前只有一個 project，未驗證實際隔離效果
- impact :: 新增專案時可能出現意外行為
- proposed_solution :: 下一個 demo app 時建立獨立 project 測試

### GAP-005 Agent tools 設定 'mcp' 不正確（已修復）

- gap_id :: GAP-005
- status :: FIXED
- description :: agent.md 中 tools 欄位設為 'mcp'，正確寫法應為 'basic-memory/*'（指定 MCP server 名稱 + 工具範圍）
- fix_date :: 2026-03-17
- fix :: PM 改為 'basic-memory/*', 3 個 subagent 同步修改

## 已發現的 BUG

### BUG-001 subagent-start.ps1 仍讀舊版 JSON

- bug_id :: BUG-001
- file :: .github/hooks/subagent-start.ps1
- status :: FIXED
- fix_date :: 2026-03-17
- description :: 仍從 .github/memory/*.json 讀取記憶，未更新為 Basic Memory 版本
- fix :: 改為注入 search_notes 提示 + agent 對應的 memory-kb folder 路徑 + 列出現有筆記 + 記錄啟動時間戳

### BUG-002 pre-compact.ps1 仍讀舊版 JSON

- bug_id :: BUG-002
- file :: .github/hooks/pre-compact.ps1
- status :: FIXED
- fix_date :: 2026-03-17
- description :: 仍讀 .github/memory/project-state.json，未更新為 Basic Memory
- fix :: 改為讀取 memory-kb/project/project-overview.md，提取 Observations + 列出各 folder 筆記數量

## 用 Hook 強制記憶的可行方案

Hook 無法直接呼叫 MCP 工具，但可以偵測 MCP 呼叫的結果（Markdown 檔案變更）：

1. **SubagentStart** → 注入 additionalContext：「你必須在完成前用 write_note 或直接編輯 memory-kb 更新記憶」
2. **SubagentStop** → 檢查 .github/memory-kb/{agent-folder}/ 的檔案修改時間（與 subagent 啟動時間比較），若無新增/修改 → 注入強烈警告
3. **Stop** → 同上，檢查整個 memory-kb 是否有本次會話的更新
4. 最佳化：SubagentStop 若偵測到未更新，可返回 `continue: false` 阻止完成（激進方案）

## Relations

- relates_to [[Development Session 2026-03-17]]
- relates_to [[Known Issues Registry]]
- blocks [[v0.03 Planning]]
