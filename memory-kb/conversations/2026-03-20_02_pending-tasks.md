---
title: 2026-03-20_02_pending-tasks
type: note
permalink: multi-agent-system/conversations/2026-03-20-02-pending-tasks
tags:
- app:general
- agent:pm
- type:session
---

# 待辦事項（2026-03-20）

## 未完成任務

### 1. 確認 Copilot 修正的跨平台安全性
- 背景：使用者更換至 Windows 環境後，Claude Code 出現 session ID 錯誤
- Copilot 協助修正（見 git diff）
- **待做：** 審查 Copilot 的修正內容，確認是否影響 macOS / Linux

### 2. README 補充一般對話使用範例
- 目前 README 只有 PM agent 的使用情境
- **待做：** 補充以下內容：
  - 在全新環境喚醒記憶的 SOP（`/continue` 或說「繼續」）
  - 是否需要關鍵字觸發記憶載入
  - 與一般 agent（非 PM）對話的範例流程
  - 兩平台（Claude Code / Copilot）同時使用時的注意事項

## Observations

- app :: general
- agent :: pm
- type :: session
- date :: 2026-03-20