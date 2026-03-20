#!/bin/bash
# PostToolUse Hook - 記錄工具使用（審計日誌）
# Claude Code hook event: PostToolUse

python3 -c '
import sys, json, os, datetime

try:
    input_str = sys.stdin.read()
    if not input_str:
        print(json.dumps({"continue": True}))
        sys.exit(0)

    data = json.loads(input_str)
    tool_name = data.get("tool_name", "unknown")
    tool_input = data.get("tool_input", {})
    tool_response = data.get("tool_response", "")
    timestamp = datetime.datetime.now().isoformat()

    today = datetime.datetime.now().strftime("%Y-%m-%d")
    log_dir = ".claude/logs"
    os.makedirs(log_dir, exist_ok=True)
    log_file = os.path.join(log_dir, f"tool-usage-{today}.log")

    response_length = len(str(tool_response)) if tool_response is not None else 0

    log_entry = {
        "timestamp": timestamp,
        "tool_name": tool_name,
        "tool_input": tool_input,
        "response_length": response_length,
        "status": "SUCCESS"
    }

    with open(log_file, "a") as f:
        f.write(json.dumps(log_entry, ensure_ascii=False) + "\n")

    print(json.dumps({"continue": True}))

except Exception as e:
    print(json.dumps({"continue": True}))
' || echo '{"continue": true}'
