---
title: 2026-03-20_01_shared-memory-kb-migration
type: note
permalink: multi-agent-system/conversations/2026-03-20-01-shared-memory-kb-migration
tags:
- app:general
- agent:claude
- type:session
---

# 重大架構改動：memory-kb 移至根目錄（共用）

## 問題根源

系統同時存在兩份 memory-kb：
- `.claude/memory-kb/` — Claude Code 版本
- `.github/memory-kb/` — VS Code Copilot 版本

Basic Memory MCP project path 指向 `.github/memory-kb/`，導致 Claude Code 的 write_note 寫入錯誤資料夾。

## 解決方案

### 目錄搬移
- `.github/memory-kb/` → `memory-kb/`（根目錄，兩平台共用）
- 刪除 `.claude/memory-kb/`（合併前補齊唯一差異：`topics/_index.json`）

### Basic Memory 專案路徑更新
```
uvx basic-memory project remove "multi-agent-system"
uvx basic-memory project add "multi-agent-system" "C:/code/projects/multi_agent_system/memory-kb"
```

### 全量路徑引用更新（30+ 處）
| 文件類別 | 舊路徑 | 新路徑 |
|---------|--------|--------|
| .claude/hooks/*.sh | `.claude/memory-kb` | `memory-kb` |
| .claude/agents/*.md | `.claude/memory-kb` | `memory-kb` |
| .github/hooks/*.sh/.ps1 | `.github/memory-kb` | `memory-kb` |
| .github/agents/*.md | `.github/memory-kb` | `memory-kb` |
| CLAUDE.md / copilot-instructions.md | platform-specific | `memory-kb` |
| ARCHITECTURE.md / README.md / setup.sh | both | `memory-kb` |

## 結果

- 兩平台（Claude Code + VS Code Copilot）讀寫同一份 `memory-kb/`
- 可同時混用兩個平台，記憶完全共享
- 不再有寫錯位置的可能

## Observations

- app :: general
- agent :: claude
- type :: session
- date :: 2026-03-20