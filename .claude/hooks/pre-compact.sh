#!/bin/bash
# PreCompact Hook - 壓縮前保護關鍵狀態 + 主題記憶提醒
# Claude Code hook event: PreCompact

python3 -c '
import sys, json, os, datetime

try:
    input_str = sys.stdin.read()
    if not input_str:
        sys.exit(0)

    data = json.loads(input_str)
    memory_kb = ".claude/memory-kb"
    log_dir = ".claude/logs"
    os.makedirs(log_dir, exist_ok=True)

    with open(os.path.join(log_dir, "hook-flow.log"), "a") as f:
        f.write(f"[{datetime.datetime.now().strftime(\"%Y-%m-%d %H:%M:%S\")}] [PreCompact] Context compaction triggered\n")

    sections = []

    # 1. 專案摘要
    overview_file = os.path.join(memory_kb, "project", "project-overview.md")
    if os.path.exists(overview_file):
        observations = []
        with open(overview_file, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if " :: " in line and line.startswith("- "):
                    observations.append(line)

        obs_text = "\n".join(observations[:10])

        folders = ["project", "crawler", "database", "frontend", "contracts", "conversations", "topics"]
        note_counts = []
        for folder in folders:
            folder_path = os.path.join(memory_kb, folder)
            if os.path.isdir(folder_path):
                count = sum(1 for f in os.listdir(folder_path) if f.endswith(".md"))
                note_counts.append(f"  - {folder}/: {count} 筆記")
        counts_text = "\n".join(note_counts)

        sections.append(f"""## 專案記憶摘要（PreCompact 自動注入）

### 專案狀態:
{obs_text}

### 知識庫統計:
{counts_text}

### 記憶位置: .claude/memory-kb/
使用 `search_notes("關鍵字")` 搜尋記憶，使用 `write_note` 更新記憶。""")

    # 2. 主題記憶提醒
    sections.append("""
## ⚠️ Context 即將壓縮

對話內容即將被壓縮以節省空間。如果當前對話有重要內容尚未儲存：
1. **請立即告訴使用者**，建議用「筆記」指令儲存重點
2. 或直接用 `write_note` 存入適當的主題記憶
3. 壓縮後可用 `search_notes` 重新載入記憶""")

    output = {"continue": True}
    if sections:
        output["hookSpecificOutput"] = {
            "additionalContext": "\n\n".join(sections)
        }

    print(json.dumps(output))

except Exception as e:
    print(json.dumps({"continue": True}))
'
