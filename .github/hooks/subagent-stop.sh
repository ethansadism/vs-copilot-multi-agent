#!/bin/bash
# SubagentStop Hook - Save subagent completion report and memory
# Logs completion status

python3 -c '
import sys, json, os, datetime

try:
    input_str = sys.stdin.read()
    if not input_str:
        sys.exit(0)

    data = json.loads(input_str)
    agent_type = data.get("agent_type", "unknown")
    agent_id = data.get("agent_id", "unknown")
    session_id = data.get("sessionId", "unknown")
    
    log_dir = ".github/logs"
    reports_dir = ".github/reports"
    
    os.makedirs(reports_dir, exist_ok=True)
    os.makedirs(log_dir, exist_ok=True)
        
    timestamp_str = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    safe_agent = agent_type.replace(" ", "_")
    report_file = os.path.join(reports_dir, f"{safe_agent}-report-{timestamp_str}.md")
    
    completion_log = {
        "timestamp": datetime.datetime.now().isoformat(),
        "agent_type": agent_type,
        "agent_id": agent_id,
        "session_id": session_id,
        "status": "COMPLETED",
        "report_file": report_file
    }
    
    # Update session log
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
            
    output = {
        "continue": True,
        "hookSpecificOutput": {
            "hookEventName": "SubagentStop",
            "additionalContext": f"{agent_type} 已完成任務。請確認已用 write_note 更新記憶筆記，報告位置: {report_file}"
        }
    }
    
    print(json.dumps(output))

except Exception as e:
    print(json.dumps({"continue": True, "systemMessage": f"SubagentStop Hook Error: {str(e)}"}))
'
