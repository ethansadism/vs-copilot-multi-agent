---
title: 2026-03-18_03_contracts-folder-architecture
type: note
permalink: multi-agent-system/conversations/2026-03-18-03-contracts-folder-architecture
tags:
- app:general
- agent:pm
- session
---

# contracts/ 資料夾架構決策

## 背景

PM 的介面合約（跨 agent 共用的 API endpoint / DB schema / WebSocket 事件名規格）原本放在 `project/`。
但 SubagentStart hook 只自動列出各 agent 自己的資料夾筆記，subagent 無法被動發現 `project/` 中的合約。
且合約是跨 session 持久的重要文件，語意上不屬於「PM 的專案筆記」。

## 決策

建立獨立的 `contracts/` 資料夾，與 project/ 平級：

```
.github/memory-kb/
├── contracts/       ← 新增：跨 agent 介面合約（PM 寫入，所有 agent 可讀）
├── conversations/
├── project/
├── crawler/
├── database/
└── frontend/
```

## 改動清單

1. **SubagentStart hooks (sh + ps1)**: 新增 contracts/ 列舉，所有 subagent 啟動時自動看到合約筆記
2. **pm.agent.md**: 規則 5 改用 contracts/，title 格式改為 `{app-id}_{seq}_contracts`，Step 1 加入合約搜尋
3. **copilot-instructions.md**: 加 contracts/ 到資料夾結構、tag 加 `type:contract`、新增命名規則
4. **ARCHITECTURE.md + README.md**: 資料夾樹加 contracts/

## 合約筆記規範

- **寫入者**: 僅 PM
- **讀取者**: 所有 agent（透過 hook 自動發現 + PM 在任務描述附 permalink）
- **title 格式**: `{app-id}_{seq}_contracts`
- **必填 tags**: `["app:{app-id}", "agent:pm", "type:contract"]`
- **跨 session 持久**: 新 session 的 PM 在 Step 1 用 `search_notes("contracts", tags=["app:xxx", "type:contract"])` 查詢

## Observations

- app :: general
- agent :: pm
- type :: session
- decision :: contracts/ 獨立資料夾取代 project/ 存放合約
- visibility :: SubagentStart hook 自動列出 contracts/ 筆記給所有 subagent

## Relations

- follows [[2026-03-18_02_mta-demo4-gap004]]
- relates_to [[general_001_memory-system-gaps]]