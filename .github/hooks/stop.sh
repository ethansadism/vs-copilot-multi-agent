#!/bin/bash
# Stop Hook - 會話結束前檢查記憶是否已更新
# 如果 project-state.json 在本次會話中未被修改，注入提醒

python3 -c '
import sys, json, os, time

try:
    input_str = sys.stdin.read()
    if not input_str:
        sys.exit(0)

    data = json.loads(input_str)
    memory_file = ".github/memory/project-state.json"

    # 檢查 project-state.json 是否在最近 10 分鐘內被修改過
    # 如果沒有，提醒 agent 更新記憶
    if os.path.exists(memory_file):
        mtime = os.path.getmtime(memory_file)
        age_minutes = (time.time() - mtime) / 60

        if age_minutes > 10:
            # 記憶文件未在近期更新，注入提醒
            output = {
                "continue": True,
                "hookSpecificOutput": {
                    "additionalContext": (
                        "## 記憶更新提醒\n"
                        "project-state.json 在本次會話中似乎未被更新。\n"
                        "請在結束前更新記憶：\n"
                        "- 記錄本次完成的任務\n"
                        "- 記錄新發現的問題和解決方案\n"
                        "- 更新系統狀態\n"
                    )
                }
            }
        else:
            output = {"continue": True}
    else:
        output = {"continue": True}

    print(json.dumps(output))

except Exception as e:
    print(json.dumps({"continue": True}))
'
