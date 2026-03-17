#!/bin/bash
# SubagentStart Hook - 注入 Basic Memory 記憶提示給 Subagent
# v0.02: 改用 Basic Memory (memory-kb)，不再讀 JSON

python3 -c '
import sys, json, os, glob, datetime

try:
    input_str = sys.stdin.read()
    if not input_str:
        sys.exit(0)

    data = json.loads(input_str)
    agent_type = data.get("agent_type", "unknown")
    agent_id = data.get("agent_id", "unknown")
    memory_kb = ".github/memory-kb"
    log_dir = ".github/logs"

    os.makedirs(log_dir, exist_ok=True)

    # 流程日誌
    with open(os.path.join(log_dir, "hook-flow.log"), "a") as f:
        f.write(f"[{datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] [SubagentStart] >>> {agent_type} (ID: {agent_id}) spawned\n")

    folder_map = {
        "Crawler Expert": "crawler",
        "Database Expert": "database",
        "Frontend Engineer": "frontend"
    }

    agent_folder = folder_map.get(agent_type, "")

    # 列出該 agent 資料夾中的現有筆記
    notes_list = ""
    folder_path = os.path.join(memory_kb, agent_folder) if agent_folder else ""
    if folder_path and os.path.isdir(folder_path):
        notes = [f for f in os.listdir(folder_path) if f.endswith(".md")]
        if notes:
            notes_list = "\n".join(f"  - {n}" for n in sorted(notes))

    # 記錄啟動時間戳（供 SubagentStop 檢查記憶更新）
    ts_file = os.path.join(log_dir, f"subagent-start-{agent_id}.timestamp")
    with open(ts_file, "w") as f:
        f.write(datetime.datetime.now().isoformat())

    context = f"""## {agent_type} Basic Memory 已就緒 (Agent ID: {agent_id})

你的記憶資料夾: `{memory_kb}/{agent_folder}/`

### 現有筆記:
{notes_list}

### 必做事項（強制）:
1. **任務開始前** — 用 `search_notes("相關關鍵字")` 搜尋過去經驗
2. **任務完成後** — 用 `write_note` 在 `{agent_folder}/` 資料夾更新或新增筆記
3. **未更新記憶 = 任務未完成**（SubagentStop 會自動偵測）

### 筆記格式:
```markdown
# 標題
描述。
## Observations
- key :: value
## Relations
- relates_to [[其他筆記]]
```
"""

    output = {
        "continue": True,
        "hookSpecificOutput": {
            "hookEventName": "SubagentStart",
            "additionalContext": context
        }
    }

    print(json.dumps(output))

except Exception as e:
    print(json.dumps({"continue": True, "systemMessage": f"SubagentStart Hook Error: {str(e)}"}))
'
