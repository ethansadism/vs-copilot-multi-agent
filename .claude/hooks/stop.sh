#!/bin/bash
# Stop Hook - 會話結束前檢查記憶是否已更新
# Claude Code hook event: Stop

source "$(dirname "$0")/detect-python.sh"
$PYTHON -c '
import sys, json, os, time

try:
    input_str = sys.stdin.read()
    if not input_str:
        print(json.dumps({"continue": True}))
        sys.exit(0)

    data = json.loads(input_str)
    overview_file = "memory-kb/project/project-overview.md"

    if os.path.exists(overview_file):
        mtime = os.path.getmtime(overview_file)
        age_minutes = (time.time() - mtime) / 60

        if age_minutes > 10:
            output = {
                "continue": True,
                "hookSpecificOutput": {
                    "additionalContext": (
                        "## 記憶更新提醒\n"
                        "project-overview.md 在本次會話中似乎未被更新。\n"
                        "請在結束前用 `write_note` 更新記憶：\n"
                        "- 記錄本次完成的任務\n"
                        "- 記錄新發現的問題和解決方案（更新 known-issues.md）\n"
                        "- 更新系統狀態\n"
                    )
                }
            }
        else:
            output = {"continue": True}
    else:
        output = {"continue": True, "systemMessage": "警告：找不到 project-overview.md"}

    print(json.dumps(output))

except Exception as e:
    print(json.dumps({"continue": True}))
' || echo '{"continue": true}'
