#!/bin/bash
# SessionStart Hook - Initialize session and load Basic Memory
# This script runs at the start of an Agent session

python3 -c '
import sys, json, os

try:
    input_str = sys.stdin.read()
    if not input_str:
        sys.exit(0)
    
    data = json.loads(input_str)
    session_id = data.get("sessionId", "unknown")
    memory_kb = "memory-kb"
    overview_file = os.path.join(memory_kb, "project", "project-overview.md")
    
    if os.path.exists(overview_file):
        additional_context = f"""
## Basic Memory 已就緒 (Session: {session_id})

記憶知識庫位於 `{memory_kb}/`，請使用 MCP 工具操作：
- `search_notes("project overview")` 查詢專案狀態
- `search_notes("known issues")` 查詢已知問題
- `search_notes("關鍵字")` 搜尋相關經驗

### 資料夾結構
- `project/` — 專案總覽與已知問題
- `crawler/` — 爬蟲經驗與最佳實踐
- `database/` — 資料模型與 SQLite 模式
- `frontend/` — 設計系統與組件庫

**請先用 search_notes 查詢記憶再開始工作。**
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
        print(json.dumps({"continue": True, "systemMessage": "警告：找不到記憶知識庫，請確認 Basic Memory 已設定"}))

except Exception as e:
    print(json.dumps({"continue": True, "systemMessage": f"SessionStart Hook Error: {str(e)}"}))
'
