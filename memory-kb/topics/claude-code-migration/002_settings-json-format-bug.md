---
title: 002_settings-json-format-bug
type: note
permalink: multi-agent-system/topics/claude-code-migration/002-settings-json-format-bug
tags:
- app:general
- agent:pm
- type:topic
---

# settings.json hooks 格式錯誤事件

## Observations

- app :: general
- agent :: pm
- bug_date :: 2026-03-20
- severity :: 配置無法載入（Claude Code 完全跳過該 settings.json）
- root_cause :: subagent 研究回傳錯誤格式，未交叉驗證直接採用
- detection :: 使用者手動執行 `claude /permissions` 時發現

## Problem

settings.json 的 hooks 使用了扁平陣列格式：
```json
{ "hooks": [{ "event": "SessionStart", "type": "command", "command": "..." }] }
```

Claude Code 實際要求的是 record + matcher 結構：
```json
{ "hooks": { "SessionStart": [{ "matcher": "", "hooks": [{ "type": "command", "command": "..." }] }] } }
```

## 測試盲點

- 個別 hook 腳本（stdin JSON → stdout JSON + exit code）全部測試通過
- **但從未驗證 settings.json 能被 Claude Code 正確解析**
- 腳本測了，容器沒測

## Solution

- solution :: 修正為正確的 `{ event: [{ matcher, hooks: [...] }] }` 結構
- prevention :: 寫完設定檔後必須用平台驗證機制確認（如 `claude /permissions`）
- prevention :: subagent 回傳的格式要跟官方文件交叉驗證
- testing_rule :: 測試清單三層：腳本邏輯 + 設定檔解析 + 端到端觸發

## Relations

- part_of [[001_migration-complete]]
