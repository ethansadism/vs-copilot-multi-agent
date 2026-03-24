#!/bin/bash
# SubagentStart Hook - 注入 Basic Memory 記憶提示給 Subagent
# v0.02: 改用 Basic Memory (memory-kb)，不再讀 JSON

source "$(dirname "$0")/detect-python.sh"
$PYTHON -c '
import sys, json, os, glob, datetime

try:
    input_str = sys.stdin.read()
    if not input_str:
        sys.exit(0)

    data = json.loads(input_str)
    agent_type = data.get("agent_type", "unknown")
    agent_id = data.get("agent_id", "unknown")
    memory_kb = "memory-kb"
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

    # 列出 contracts/ 共享合約筆記（所有 agent 皆可見）
    contracts_list = ""
    contracts_path = os.path.join(memory_kb, "contracts")
    if os.path.isdir(contracts_path):
        contracts = [f for f in os.listdir(contracts_path) if f.endswith(".md")]
        if contracts:
            contracts_list = "\n".join(f"  - {n}" for n in sorted(contracts))

    # 記錄啟動時間戳（供 SubagentStop 檢查記憶更新）
    ts_file = os.path.join(log_dir, f"subagent-start-{agent_id}.timestamp")
    with open(ts_file, "w") as f:
        f.write(datetime.datetime.now().isoformat())

    context = f"""## {agent_type} Basic Memory 已就緒 (Agent ID: {agent_id})

你的記憶資料夾: `{memory_kb}/{agent_folder}/`

### 現有筆記:
{notes_list}

### 介面合約（共享，所有 agent 皆可讀）:
{contracts_list if contracts_list else '  （目前無合約）'}

> 合約筆記由 PM 建立在 `contracts/` 資料夾。如 PM 在任務描述中附了合約 permalink，請用 `read_note(permalink)` 讀取完整規格。

### 搜尋規則（必須遵守）

**精確搜尋**（避免跨 app 污染）：
```
search_notes("關鍵字", tags=["app:<app-id>"])
search_notes("關鍵字", tags=["agent:{agent_folder}"])
```

**❌ 禁止**直接用 `search_notes("關鍵字")` 而不帶 tags，這會混入其他 app 的結果。
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
