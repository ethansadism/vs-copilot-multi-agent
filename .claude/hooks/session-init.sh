#!/bin/bash
# SessionStart Hook - 初始化 session，顯示主題記憶選單
# Claude Code hook event: SessionStart

python3 -c '
import sys, json, os

try:
    input_str = sys.stdin.read()
    if not input_str:
        sys.exit(0)

    data = json.loads(input_str)
    memory_kb = ".claude/memory-kb"
    topics_dir = os.path.join(memory_kb, "topics")
    index_file = os.path.join(topics_dir, "_index.json")
    overview_file = os.path.join(memory_kb, "project", "project-overview.md")

    sections = []

    # 1. 檢查 Basic Memory 是否就緒
    if os.path.exists(overview_file):
        sections.append("## Basic Memory 已就緒")
        sections.append("")
        sections.append("記憶知識庫位於 `.claude/memory-kb/`，請使用 MCP 工具操作：")
        sections.append("- `search_notes(\"project overview\")` 查詢專案狀態")
        sections.append("- `search_notes(\"known issues\")` 查詢已知問題")
        sections.append("")
    else:
        sections.append("⚠️ 找不到 project-overview.md，請確認 Basic Memory 已設定")
        sections.append("")

    # 2. 顯示主題記憶選單
    if os.path.exists(index_file):
        with open(index_file, "r", encoding="utf-8") as f:
            index = json.load(f)

        active_topics = [t for t in index.get("topics", []) if t.get("status") == "active"]

        if active_topics:
            sections.append("## 進行中的主題記憶")
            sections.append("")
            for i, topic in enumerate(active_topics, 1):
                name = topic.get("name", "unnamed")
                desc = topic.get("description", "")
                updated = topic.get("updated_at", "unknown")
                note_count = 0
                topic_dir = os.path.join(topics_dir, name)
                if os.path.isdir(topic_dir):
                    note_count = len([f for f in os.listdir(topic_dir) if f.endswith(".md")])
                sections.append(f"{i}. **{name}** — {desc} ({note_count} 筆記，更新於 {updated})")
            sections.append("")
            sections.append("請選擇要載入的主題（輸入編號或名稱），或直接開始新對話。")
            sections.append("")
    else:
        sections.append("## 主題記憶")
        sections.append("目前沒有進行中的主題。對話中說「筆記」可建立新主題。")
        sections.append("")

    # 3. SOP 提醒
    sections.append("**請先用 search_notes 查詢記憶再開始工作。**")

    output = {
        "continue": True,
        "hookSpecificOutput": {
            "additionalContext": "\n".join(sections)
        }
    }
    print(json.dumps(output))

except Exception as e:
    print(json.dumps({"continue": True, "systemMessage": f"SessionStart Hook Error: {str(e)}"}))
'
