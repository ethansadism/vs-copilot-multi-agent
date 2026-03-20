#!/bin/bash
# PreCompact Hook - 在 context 被壓縮前保護關鍵狀態
# v0.02: 改用 Basic Memory (memory-kb)，不再讀 JSON

python3 -c '
import sys, json, os

try:
    input_str = sys.stdin.read()
    if not input_str:
        sys.exit(0)

    data = json.loads(input_str)
    memory_kb = "memory-kb"
    log_dir = ".github/logs"

    os.makedirs(log_dir, exist_ok=True)

    import datetime
    with open(os.path.join(log_dir, "hook-flow.log"), "a") as f:
        trigger = data.get("trigger", "unknown")
        f.write(f"[{datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] [PreCompact] Context compaction triggered (reason: {trigger})\n")

    summary = ""
    overview_file = os.path.join(memory_kb, "project", "project-overview.md")
    if os.path.exists(overview_file):
        # 提取 Observations 中的關鍵資訊
        observations = []
        with open(overview_file, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if " :: " in line and line.startswith("- "):
                    observations.append(line)

        obs_text = "\n".join(observations[:10])

        # 各 folder 筆記數量
        folders = ["project", "crawler", "database", "frontend"]
        note_counts = []
        for folder in folders:
            folder_path = os.path.join(memory_kb, folder)
            count = len([f for f in os.listdir(folder_path) if f.endswith(".md")]) if os.path.isdir(folder_path) else 0
            note_counts.append(f"  - {folder}/: {count} 筆記")
        counts_text = "\n".join(note_counts)

        summary = f"""## 專案記憶摘要（PreCompact 自動注入）

### 專案狀態:
{obs_text}

### 知識庫統計:
{counts_text}

### 記憶位置: memory-kb/
使用 `search_notes("關鍵字")` 搜尋記憶，使用 `write_note` 更新記憶。
"""

    output = {"continue": True}
    if summary:
        output["hookSpecificOutput"] = {
            "hookEventName": "PreCompact",
            "additionalContext": summary
        }

    print(json.dumps(output))

except Exception as e:
    print(json.dumps({"continue": True}))
'
