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
    agent_type = data.get("agent_type")
    agent_id = data.get("agent_id")
    session_id = data.get("sessionId")
    
    memory_dir = ".github/memory"
    reports_dir = ".github/reports"
    
    if not os.path.exists(reports_dir):
        os.makedirs(reports_dir, exist_ok=True)
        
    timestamp_str = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    report_file = os.path.join(reports_dir, f"{agent_type.replace(" ", "_")}-report-{timestamp_str}.md")
    
    completion_log = {
        "timestamp": datetime.datetime.now().isoformat(),
        "agent_type": agent_type,
        "agent_id": agent_id,
        "session_id": session_id,
        "status": "COMPLETED",
        "report_file": report_file
    }
    
    # Update session log
    session_log_path = os.path.join(memory_dir, f"session-{session_id}.json")
    
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
        # Create new session log if not exists
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
            "additionalContext": f"{agent_type} has completed execution. Report location: {report_file}"
        }
    }
    
    print(json.dumps(output))

except Exception as e:
    print(json.dumps({"continue": True, "systemMessage": f"SubagentStop Hook Error: {str(e)}"}))
'
