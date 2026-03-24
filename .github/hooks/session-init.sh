#!/bin/bash
# SessionStart Hook - Initialize session and load Basic Memory
# This script runs at the start of an Agent session

source "$(dirname "$0")/detect-python.sh"
$PYTHON -c '
import sys, json, os

try:
    input_str = sys.stdin.read()
    if not input_str:
        sys.exit(0)

    data = json.loads(input_str)
    session_id = data.get("sessionId", "unknown")
    memory_kb = "memory-kb"

    if os.path.isdir(memory_kb):
        additional_context = f"""
## Basic Memory 已就緒 (Session: {session_id})

記憶知識庫位於 `{memory_kb}/`，請使用 MCP 工具操作：
- `recent_activity(timeframe="7d")` 查詢最近活動（一般對話恢復用）
- `search_notes("project overview")` 查詢專案狀態（PM 模式用）
- `search_notes("關鍵字")` 搜尋相關經驗

### 資料夾結構
- `project/` — 專案總覽（PM 維護）
- `conversations/` — 重要對話紀錄（一般模式恢復用）
- `crawler/` `database/` `frontend/` — 各角色的領域經驗

### 模式說明
- **一般對話（預設）**：直接對話，恢復進度請說「繼續」
- **PM 多 Agent 模式**：說「啟動 PM」切換，PM 會協調多個 subagent
"""
        output = {
            "continue": True,
            "hookSpecificOutput": {
                "hookEventName": "SessionStart",
                "additionalContext": additional_context
            }
        }
        print(json.dumps(output))
    else:
        print(json.dumps({"continue": True, "systemMessage": "警告：找不到 memory-kb/ 目錄，請先執行 bootstrap.sh 或 setup.sh"}))

except Exception as e:
    print(json.dumps({"continue": True, "systemMessage": f"SessionStart Hook Error: {str(e)}"}))
'
