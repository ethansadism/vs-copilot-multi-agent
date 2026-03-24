#!/bin/bash
# PreCompact Hook - 壓縮前自動記錄 session 活動 + 注入關鍵狀態
# Claude Code hook event: PreCompact

source "$(dirname "$0")/detect-python.sh"
$PYTHON -c '
import sys, json, os, datetime, subprocess

try:
    input_str = sys.stdin.read()
    if not input_str:
        print(json.dumps({"continue": True}))
        sys.exit(0)

    data = json.loads(input_str)
    memory_kb = "memory-kb"
    log_dir = ".claude/logs"
    conversations_dir = os.path.join(memory_kb, "conversations")
    os.makedirs(log_dir, exist_ok=True)
    os.makedirs(conversations_dir, exist_ok=True)

    now = datetime.datetime.now()
    now_str = now.strftime("%Y-%m-%d %H:%M:%S")

    with open(os.path.join(log_dir, "hook-flow.log"), "a") as f:
        f.write(f"[{now_str}] [PreCompact] Context compaction triggered\n")

    # ============================================================
    # 1. 自動記錄 session 活動到 memory-kb/conversations/
    # ============================================================
    activity_lines = []

    # 1a. 從 hook-flow.log 提取本次 session 事件
    log_file = os.path.join(log_dir, "hook-flow.log")
    if os.path.exists(log_file):
        with open(log_file, "r", encoding="utf-8") as f:
            lines = f.readlines()
        # 找最近一次 SessionStart 之後的所有事件
        session_events = []
        for line in reversed(lines):
            session_events.insert(0, line.strip())
            if "[SessionStart]" in line:
                break
        if session_events:
            activity_lines.append("### Hook 事件")
            for evt in session_events[-30:]:  # 最多 30 筆
                activity_lines.append(f"- {evt}")

    # 1b. 本次 session 修改的 memory-kb 檔案
    modified_notes = []
    for root, dirs, files in os.walk(memory_kb):
        for fname in files:
            if fname.endswith(".md") and not fname.startswith("."):
                fpath = os.path.join(root, fname)
                mtime = datetime.datetime.fromtimestamp(os.path.getmtime(fpath))
                # 過去 2 小時內修改的筆記（涵蓋大多數 session 長度）
                if (now - mtime).total_seconds() < 7200:
                    rel = os.path.relpath(fpath, memory_kb).replace("\\\\", "/")
                    modified_notes.append((mtime.strftime("%H:%M"), rel))
    if modified_notes:
        modified_notes.sort()
        activity_lines.append("")
        activity_lines.append("### 本次修改的筆記")
        for t, note in modified_notes:
            activity_lines.append(f"- [{t}] {note}")

    # 1c. git diff --name-only（本次 session 修改的程式碼）
    try:
        result = subprocess.run(
            ["git", "diff", "--name-only", "HEAD"],
            capture_output=True, text=True, timeout=5
        )
        changed_files = [f for f in result.stdout.strip().splitlines() if f]
        if changed_files:
            activity_lines.append("")
            activity_lines.append("### 未提交的程式碼變更")
            for f in changed_files[:20]:  # 最多 20 筆
                activity_lines.append(f"- {f}")
    except Exception:
        pass

    # 寫入 session 活動筆記
    if activity_lines:
        date_str = now.strftime("%Y-%m-%d")
        time_str = now.strftime("%H:%M")

        # 計算當天序號
        existing = [f for f in os.listdir(conversations_dir)
                    if f.startswith(date_str) and f.endswith(".md")]
        seq = len(existing) + 1

        title = f"{date_str}_{seq:02d}_auto-compact"
        filename = f"{title}.md"
        filepath = os.path.join(conversations_dir, filename)

        content = f"""---
title: {title}
permalink: conversations/{title}
tags:
  - type:session
  - agent:system
  - app:general
---

# Session 活動紀錄（PreCompact 自動產生）

- date :: {date_str} {time_str}
- trigger :: context compaction
- source :: hook-flow.log + filesystem mtime + git diff

{chr(10).join(activity_lines)}

## Observations

- type :: session-activity
- auto_generated :: true
- date :: {date_str} {time_str}
"""
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(content)

        with open(os.path.join(log_dir, "hook-flow.log"), "a") as f:
            f.write(f"[{now_str}] [PreCompact] Auto-saved session note: {filename}\n")

    # ============================================================
    # 2. 注入專案摘要到壓縮 context
    # ============================================================
    sections = []

    overview_file = os.path.join(memory_kb, "project", "project-overview.md")
    if os.path.exists(overview_file):
        observations = []
        with open(overview_file, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if " :: " in line and line.startswith("- "):
                    observations.append(line)

        obs_text = "\\n".join(observations[:10])

        folders = ["project", "crawler", "database", "frontend", "contracts", "conversations", "topics"]
        note_counts = []
        for folder in folders:
            folder_path = os.path.join(memory_kb, folder)
            if os.path.isdir(folder_path):
                count = sum(1 for f in os.listdir(folder_path) if f.endswith(".md"))
                note_counts.append(f"  - {folder}/: {count} 筆記")
        counts_text = "\\n".join(note_counts)

        sections.append(f"""## 專案記憶摘要（PreCompact 自動注入）

### 專案狀態:
{obs_text}

### 知識庫統計:
{counts_text}

### 記憶位置: memory-kb/
使用 `search_notes("關鍵字")` 搜尋記憶，使用 `write_note` 更新記憶。""")

    # 加上剛寫入的 session note 路徑提示
    if activity_lines:
        sections.append(f"""## Session 活動已自動記錄

已自動寫入: `memory-kb/conversations/{filename}`
壓縮後可用 `read_note("conversations/{title}")` 讀取本次 session 的活動軌跡。""")

    output = {"continue": True}
    if sections:
        output["hookSpecificOutput"] = {
            "additionalContext": "\\n\\n".join(sections)
        }

    print(json.dumps(output))

except Exception as e:
    with open(os.path.join(".claude", "logs", "hook-error.log"), "a") as f:
        f.write(f"[PreCompact Error] {str(e)}\\n")
    print(json.dumps({"continue": True}))
' || echo '{"continue": true}'
