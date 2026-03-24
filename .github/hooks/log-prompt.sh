#!/bin/bash
# UserPromptSubmit Hook - Log user prompts
# Used for audit and session recovery

source "$(dirname "$0")/detect-python.sh"
$PYTHON -c '
import sys, json, os, datetime

try:
    input_str = sys.stdin.read()
    if not input_str:
        sys.exit(0)
        
    data = json.loads(input_str)
    prompt = data.get("prompt")
    session_id = data.get("sessionId")
    timestamp = data.get("timestamp", datetime.datetime.now().isoformat())
    
    # Log directory and file
    today = datetime.datetime.now().strftime("%Y-%m-%d")
    log_dir = ".github/logs"
    log_file = os.path.join(log_dir, f"prompts-{today}.log")
    
    if not os.path.exists(log_dir):
        os.makedirs(log_dir, exist_ok=True)
        
    log_entry = {
        "timestamp": timestamp,
        "session_id": session_id,
        "prompt": prompt
    }
    
    with open(log_file, "a") as f:
        f.write(json.dumps(log_entry) + "\n")
        
    print(json.dumps({"continue": True}))

except Exception as e:
    # Fail gracefully
    print(json.dumps({"continue": True}))
'
