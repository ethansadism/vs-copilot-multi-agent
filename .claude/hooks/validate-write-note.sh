#!/bin/bash
# PreToolUse Hook - 驗證 write_note 的 tags 格式
# Claude Code hook event: PreToolUse (matcher: mcp__basic-memory__write_note)
# 如果 tags 缺少 app: 或 agent: 前綴，exit 2 阻擋

HOOK_INPUT=$(cat)
export HOOK_INPUT

python3 -c '
import sys, json, os

try:
    input_str = os.environ.get("HOOK_INPUT", "")
    if not input_str:
        sys.exit(0)

    data = json.loads(input_str)
    tool_input = data.get("tool_input", {})

    tags = tool_input.get("tags", [])
    folder = tool_input.get("folder", "")
    title = tool_input.get("title", "")

    # topics/ 資料夾的筆記用不同的 tag 規範
    if folder.startswith("topics"):
        has_type = any(t.startswith("type:") for t in tags)
        has_topic = any(t.startswith("topic:") for t in tags)
        if not has_type or not has_topic:
            output = {
                "decision": "block",
                "reason": "主題筆記的 tags 必須包含 type:topic 和 topic:{topic-name}。當前 tags: " + str(tags)
            }
            print(json.dumps(output))
            sys.exit(2)
        print(json.dumps({"decision": "approve"}))
        sys.exit(0)

    # contracts/ 的驗證
    if folder == "contracts":
        has_type = any(t == "type:contract" for t in tags)
        has_app = any(t.startswith("app:") for t in tags)
        if not has_type or not has_app:
            output = {
                "decision": "block",
                "reason": "合約筆記的 tags 必須包含 app:xxx 和 type:contract。當前 tags: " + str(tags)
            }
            print(json.dumps(output))
            sys.exit(2)
        print(json.dumps({"decision": "approve"}))
        sys.exit(0)

    # 一般筆記（crawler/, database/, frontend/, project/）
    has_app = any(t.startswith("app:") for t in tags)
    has_agent = any(t.startswith("agent:") for t in tags)

    if not has_app or not has_agent:
        missing = []
        if not has_app:
            missing.append("app:xxx")
        if not has_agent:
            missing.append("agent:xxx")
        missing_str = ", ".join(missing)
        output = {
            "decision": "block",
            "reason": "write_note tags 缺少必填項: " + missing_str + "。當前 tags: " + str(tags) + "。請補上後重試。"
        }
        print(json.dumps(output))
        sys.exit(2)

    print(json.dumps({"decision": "approve"}))

except Exception as e:
    print(json.dumps({"decision": "approve"}))
'
