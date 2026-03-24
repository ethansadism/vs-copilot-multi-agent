#!/bin/bash
# SubagentStop Hook - 記錄 Subagent 完成 + 偵測記憶是否更新
# v0.02: 新增記憶更新偵測機制

source "$(dirname "$0")/detect-python.sh"
$PYTHON -c '
import sys, json, os, datetime

try:
    input_str = sys.stdin.read()
    if not input_str:
        sys.exit(0)

    data = json.loads(input_str)
    agent_type = data.get("agent_type", "unknown")
    agent_id = data.get("agent_id", "unknown")
    session_id = data.get("sessionId", "unknown")

    memory_kb = "memory-kb"
    log_dir = ".github/logs"
    reports_dir = ".github/reports"

    os.makedirs(reports_dir, exist_ok=True)
    os.makedirs(log_dir, exist_ok=True)

    # 流程日誌
    with open(os.path.join(log_dir, "hook-flow.log"), "a") as f:
        f.write(f"[{datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] [SubagentStop] <<< {agent_type} (ID: {agent_id}) completed\n")

    timestamp_str = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    safe_agent = agent_type.replace(" ", "_")
    report_file = os.path.join(reports_dir, f"{safe_agent}-report-{timestamp_str}.md")

    # 記錄完成事件到 session log
    completion_log = {
        "timestamp": datetime.datetime.now().isoformat(),
        "agent_type": agent_type,
        "agent_id": agent_id,
        "session_id": session_id,
        "status": "COMPLETED",
        "report_file": report_file
    }

    session_log_path = os.path.join(log_dir, f"session-{session_id}.json")
    if os.path.exists(session_log_path):
        try:
            with open(session_log_path, "r") as f:
                log = json.load(f)
        except:
            log = {}
        if "completed_agents" not in log:
            log["completed_agents"] = []
        log["completed_agents"].append(completion_log)
        with open(session_log_path, "w") as f:
            json.dump(log, f, indent=2)
    else:
        log = {
            "session_id": session_id,
            "started_at": datetime.datetime.now().isoformat(),
            "completed_agents": [completion_log]
        }
        with open(session_log_path, "w") as f:
            json.dump(log, f, indent=2)

    # === 記憶更新偵測 ===
    folder_map = {
        "Crawler Expert": "crawler",
        "Database Expert": "database",
        "Frontend Engineer": "frontend"
    }
    agent_folder = folder_map.get(agent_type, "")
    memory_updated = False
    warning = ""

    # 讀取 SubagentStart 記錄的啟動時間戳
    ts_file = os.path.join(log_dir, f"subagent-start-{agent_id}.timestamp")
    if os.path.exists(ts_file):
        with open(ts_file, "r") as f:
            start_time = datetime.datetime.fromisoformat(f.read().strip())
        os.remove(ts_file)
    else:
        start_time = datetime.datetime.now() - datetime.timedelta(minutes=10)

    # 檢查 agent 的 memory-kb folder 是否有新增或修改的檔案
    folder_path = os.path.join(memory_kb, agent_folder) if agent_folder else ""
    if folder_path and os.path.isdir(folder_path):
        updated_notes = []
        for fname in os.listdir(folder_path):
            if fname.endswith(".md"):
                fpath = os.path.join(folder_path, fname)
                mtime = datetime.datetime.fromtimestamp(os.path.getmtime(fpath))
                if mtime > start_time:
                    updated_notes.append(fname)
                    memory_updated = True

    if not memory_updated:
        warning = f"""

### ⚠️ 記憶未更新警告
{agent_type} 在本次任務中**未更新記憶筆記**（{memory_kb}/{agent_folder}/ 無新增或修改）。
請立即用 `write_note` 記錄：
- 完成了什麼任務
- 遇到的問題和解決方案
- 可複用的經驗

**未更新記憶 = 任務未完成。**
"""
    else:
        updated_list = ", ".join(updated_notes)
        warning = f"\n已偵測到記憶更新: {updated_list}"

    output = {
        "continue": True,
        "hookSpecificOutput": {
            "hookEventName": "SubagentStop",
            "additionalContext": f"{agent_type} 已完成任務。報告位置: {report_file}{warning}"
        }
    }

    print(json.dumps(output))

except Exception as e:
    print(json.dumps({"continue": True, "systemMessage": f"SubagentStop Hook Error: {str(e)}"}))
'
