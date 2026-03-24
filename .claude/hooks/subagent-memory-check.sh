#!/bin/bash
# Per-agent Stop Hook - 檢查 subagent 記憶是否已更新
# 用法：bash .claude/hooks/subagent-memory-check.sh <agent_folder>
# 如果記憶未更新，exit 2 阻擋 agent 結束
# 這個腳本由每個 subagent 的 frontmatter hooks.Stop 呼叫

AGENT_FOLDER="${1:-unknown}"
HOOK_INPUT=$(cat)
export HOOK_INPUT AGENT_FOLDER

source "$(dirname "$0")/detect-python.sh"
$PYTHON -c '
import sys, json, os, datetime

agent_folder = os.environ.get("AGENT_FOLDER", "unknown")
memory_kb = "memory-kb"
log_dir = ".claude/logs"

try:
    input_str = os.environ.get("HOOK_INPUT", "")
    data = json.loads(input_str) if input_str else {}
    agent_id = data.get("agent_id", "unknown")

    os.makedirs(log_dir, exist_ok=True)
    now_str = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open(os.path.join(log_dir, "hook-flow.log"), "a") as f:
        f.write("[" + now_str + "] [SubagentStop] <<< " + agent_folder + " (ID: " + agent_id + ") checking memory...\n")

    # 讀取 SubagentStart 記錄的啟動時間戳
    ts_file = os.path.join(log_dir, "subagent-start-" + agent_id + ".timestamp")
    if os.path.exists(ts_file):
        with open(ts_file, "r") as f:
            start_time = datetime.datetime.fromisoformat(f.read().strip())
        os.remove(ts_file)
    else:
        start_time = datetime.datetime.now() - datetime.timedelta(minutes=10)

    # 檢查 agent 的 memory-kb folder 是否有新增或修改的檔案
    folder_path = os.path.join(memory_kb, agent_folder)
    memory_updated = False
    updated_notes = []

    if os.path.isdir(folder_path):
        for fname in os.listdir(folder_path):
            if fname.endswith(".md"):
                fpath = os.path.join(folder_path, fname)
                mtime = datetime.datetime.fromtimestamp(os.path.getmtime(fpath))
                if mtime > start_time:
                    updated_notes.append(fname)
                    memory_updated = True

    if not memory_updated:
        reason = (
            agent_folder + " 在本次任務中未更新記憶筆記（" + memory_kb + "/" + agent_folder + "/ 無新增或修改）。"
            "請立即用 write_note 記錄：完成了什麼任務、遇到的問題和解決方案、可複用的經驗。"
            "未更新記憶 = 任務未完成。"
        )
        output = {
            "decision": "block",
            "reason": reason
        }
        print(json.dumps(output))
        sys.exit(2)
    else:
        updated_list = ", ".join(updated_notes)
        now_str2 = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        with open(os.path.join(log_dir, "hook-flow.log"), "a") as f:
            f.write("[" + now_str2 + "] [SubagentStop] " + agent_folder + " memory updated: " + updated_list + "\n")
        output = {
            "continue": True,
            "hookSpecificOutput": {
                "additionalContext": "已偵測到記憶更新: " + updated_list
            }
        }
        print(json.dumps(output))

except Exception as e:
    print(json.dumps({"continue": True, "systemMessage": "SubagentStop Hook Error: " + str(e)}))
'
