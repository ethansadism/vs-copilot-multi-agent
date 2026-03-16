#!/bin/bash
# PostToolUse Hook - Log tool usage after execution
# Used for audit and memory updates

python3 -c '
import sys, json, os, datetime

try:
    input_str = sys.stdin.read()
    if not input_str:
        sys.exit(0)

    data = json.loads(input_str)
    tool_name = data.get("tool_name")
    tool_input = data.get("tool_input")
    tool_response = data.get("tool_response", "")
    timestamp = data.get("timestamp", datetime.datetime.now().isoformat())
    
    # Log directory and file
    today = datetime.datetime.now().strftime("%Y-%m-%d")
    log_dir = ".github/logs"
    log_file = os.path.join(log_dir, f"tool-usage-{today}.log")
    
    if not os.path.exists(log_dir):
        os.makedirs(log_dir, exist_ok=True)
        
    # Calculate response length safely
    response_length = len(str(tool_response)) if tool_response is not None else 0
    
    log_entry = {
        "timestamp": timestamp,
        "tool_name": tool_name,
        "tool_input": tool_input,
        "response_length": response_length,
        "status": "SUCCESS"
    }
    
    with open(log_file, "a") as f:
        f.write(json.dumps(log_entry) + "\n")
        
    print(json.dumps({"continue": True}))

except Exception as e:
    # Fail gracefully
    print(json.dumps({"continue": True}))
'
