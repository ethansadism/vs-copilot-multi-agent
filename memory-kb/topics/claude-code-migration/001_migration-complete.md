---
title: 001_migration-complete
type: note
permalink: multi-agent-system/topics/claude-code-migration/001-migration-complete
tags:
- app:general
- agent:pm
- type:topic
---

# Claude Code 移植完成紀錄

VS Code Copilot 多 agent 系統完整移植為 Claude Code 版本。

## Observations

- app :: general
- agent :: pm
- migration_date :: 2026-03-20
- source :: .github/ (VS Code Copilot)
- target :: .claude/ (Claude Code)
- version :: v0.07

## 移植內容

### Agent 對應
- .github/agents/*.agent.md → .claude/agents/*.md
- PM (opus), Crawler/Database/Frontend (sonnet) — 4 個角色保留
- Per-agent Stop hook 寫在 frontmatter，升級為 exit 2 阻擋機制

### Hook 對應（7 → 8 個）
- SessionStart → session-init.sh（新增主題選單）
- UserPromptSubmit → user-prompt-submit.sh（新增關鍵字偵測：筆記/記錄進度）
- SubagentStart → subagent-start.sh（直接移植）
- SubagentStop → subagent-memory-check.sh（升級：exit 2 阻擋，per-agent hook）
- PostToolUse → post-tool-use.sh（直接移植）
- PreCompact → pre-compact.sh（新增主題記憶提醒）
- Stop → stop.sh（直接移植）
- **新增** PreToolUse → validate-write-note.sh（驗證 write_note tags 格式）

### 升級重點
- SubagentStop 從「警告」升級為「exit 2 阻擋」
- Per-agent hooks 取代全域 hard-coded agent 名稱
- PreToolUse 驗證 write_note tags（app:/agent: 必填）
- UserPromptSubmit 關鍵字偵測觸發儲存流程

### 新增：主題記憶系統
- topics/_index.json 追蹤主題狀態（active/archived）
- SessionStart 顯示進行中主題選單
- 關鍵字觸發（筆記、記錄進度、save、note）
- PreCompact 提醒儲存
- 封存主題不自動載入（節省 token）

## 設計決策
- CLAUDE.md 放全域規則（等同 copilot-instructions.md）
- .mcp.json 放根目錄（Claude Code 標準位置）
- memory-kb 從 .github/ 複製到 .claude/（兩份並存，各自服務對應平台）
- Hook 腳本用 HOOK_INPUT=$(cat) + export 模式處理 stdin，避免 heredoc 吃掉 pipe

## Relations

- part_of [[project-overview]]
