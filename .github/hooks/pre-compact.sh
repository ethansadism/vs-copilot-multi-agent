#!/bin/bash
# PreCompact Hook - 在 context 被壓縮前保護關鍵狀態
# 當對話太長需要壓縮時，提醒 agent 當前的關鍵資訊

python3 -c '
import sys, json, os

try:
    input_str = sys.stdin.read()
    if not input_str:
        sys.exit(0)

    data = json.loads(input_str)
    memory_file = ".github/memory/project-state.json"

    context_parts = ["## Context 即將被壓縮 - 關鍵資訊保留\n"]

    # 重新注入 project-state 的關鍵資訊，避免壓縮後遺失
    if os.path.exists(memory_file):
        with open(memory_file, "r") as f:
            state = json.load(f)

        active_tasks = state.get("active_tasks", [])
        known_issues = state.get("known_issues", [])

        if active_tasks:
            context_parts.append("### 當前活躍任務:")
            for task in active_tasks:
                if isinstance(task, dict):
                    context_parts.append(f"- {task.get(\"description\", task.get(\"task_id\", str(task)))}")
                else:
                    context_parts.append(f"- {task}")

        if known_issues:
            context_parts.append("\n### 已知問題（勿重複犯錯）:")
            for issue in known_issues:
                if isinstance(issue, dict):
                    issue_id = issue.get("issue_id", "")
                    title = issue.get("title", "")
                    solution = issue.get("solution", "")
                    context_parts.append(f"- {issue_id}: {title} → 解法: {solution}")
                else:
                    context_parts.append(f"- {issue}")

    context_parts.append("\n如需完整記憶，請重新讀取 .github/memory/ 下的檔案。")

    output = {
        "continue": True,
        "hookSpecificOutput": {
            "hookEventName": "PreCompact",
            "additionalContext": "\n".join(context_parts)
        }
    }

    print(json.dumps(output))

except Exception as e:
    print(json.dumps({"continue": True}))
'
