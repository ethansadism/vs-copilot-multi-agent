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

本次對話完成了 v0.01.1 → v0.02 的重大升級。

## 完成事項

### v0.01.1 修正（已合併至 Demo-crawler-0.01 分支）
- 修正 model 格式：PM 改為 `"claude opus 4.6"`，Subagent 改為 `"claude sonnet 4.6"`（字串非陣列）
- 強化 PM 絕對不寫 code 規則（包括 app.py 整合）
- MCP 工具推薦改為主動執行
- 3 個 Subagent 新增強制錯誤記錄格式
- 報告生成改為強制（未生成報告 = 任務未完成）
- 研究記憶 MCP 選項：選擇 Basic Memory（★2.7K）

### v0.02 Basic Memory 整合（mcp-basic-memory 分支）
- 安裝 Basic Memory v0.20.2（via `uv tool install`）
- 建立 .vscode/mcp.json（`uvx basic-memory mcp --project multi-agent-system`）
- 遷移 4 個 JSON 記憶檔為 13 個 Markdown 知識筆記
- 改造 4 個 agent 使用 MCP 工具（search_notes / write_note / read_note）
- 更新 6 個 hook 腳本（ps1 + sh）
- Commit ea5e3f3，已 push 至 GitHub

## Observations

- version :: v0.02
- branch :: mcp-basic-memory
- commit :: ea5e3f3
- total_notes :: 13
- total_entities_indexed :: 13
- basic_memory_version :: 0.20.2

## Known Workaround

- python_313_issue :: bm CLI 在 Python 3.13 會 crash（FastAPI 相容性），必須用 `uv run --with basic-memory -- basic-memory <cmd>` 替代
- mcp_works_fine :: VS Code MCP 伺服器用 uvx 運行，不受此問題影響

## Next Steps

- 跑一次 demo 驗證 v0.02 的 Basic Memory 流程
- 考慮合併到 main 分支
- 可能新增更多 agent 或 MCP 工具

## Relations

- updates [[Project Overview]]
- updates [[Known Issues Registry]]
