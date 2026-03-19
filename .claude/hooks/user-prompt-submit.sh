#!/bin/bash
# UserPromptSubmit Hook - 關鍵字偵測 + 審計日誌
# Claude Code hook event: UserPromptSubmit
# 偵測「筆記」「記錄進度」等關鍵字，注入儲存提示

python3 -c '
import sys, json, os, datetime, re

try:
    input_str = sys.stdin.read()
    if not input_str:
        sys.exit(0)

    data = json.loads(input_str)
    prompt = data.get("prompt", "")
    session_id = data.get("sessionId", "unknown")
    timestamp = datetime.datetime.now().isoformat()

    # === 審計日誌 ===
    today = datetime.datetime.now().strftime("%Y-%m-%d")
    log_dir = ".claude/logs"
    os.makedirs(log_dir, exist_ok=True)
    log_file = os.path.join(log_dir, f"prompts-{today}.log")

    log_entry = {
        "timestamp": timestamp,
        "session_id": session_id,
        "prompt": prompt
    }
    with open(log_file, "a") as f:
        f.write(json.dumps(log_entry, ensure_ascii=False) + "\n")

    # === 關鍵字偵測 ===
    save_keywords = [
        "筆記", "記一下", "記錄進度", "記錄一下", "存起來",
        "save", "note this", "take note", "記住", "備忘"
    ]

    prompt_lower = prompt.lower().strip()
    triggered = any(kw in prompt_lower for kw in save_keywords)

    output = {"continue": True}

    if triggered:
        # 讀取現有主題清單
        topics_dir = ".claude/memory-kb/topics"
        index_file = os.path.join(topics_dir, "_index.json")
        topic_list = ""

        if os.path.exists(index_file):
            with open(index_file, "r", encoding="utf-8") as f:
                index = json.load(f)
            active = [t for t in index.get("topics", []) if t.get("status") == "active"]
            if active:
                topic_list = "\n".join(f"  - {t['name']}: {t.get('description', '')}" for t in active)

        context = f"""## 偵測到儲存意圖

使用者想要記錄筆記。請執行以下流程：

1. 詢問使用者要存入哪個主題（或建立新主題）
2. 整理當前對話的重點
3. 用 `write_note` 寫入 `.claude/memory-kb/topics/{{topic-name}}/` 資料夾
4. 更新 `.claude/memory-kb/topics/_index.json`

### 現有進行中的主題：
{topic_list if topic_list else "（無，需建立新主題）"}

### 筆記 title 格式：`{{seq}}_{{name}}`（如 `001_initial-design`）
### 必填 tags：`["type:topic", "topic:{{topic-name}}"]`
"""
        output["hookSpecificOutput"] = {
            "additionalContext": context
        }

    print(json.dumps(output, ensure_ascii=False))

except Exception as e:
    print(json.dumps({"continue": True}))
'
