#!/bin/bash
# SessionStart Hook - 初始化 session，顯示主題記憶選單
# Claude Code hook event: SessionStart

python3 -c '
import sys, json, os

try:
    input_str = sys.stdin.read()
    if not input_str:
        print(json.dumps({"continue": True}))
        sys.exit(0)

    data = json.loads(input_str)
    memory_kb = "memory-kb"
    topics_dir = os.path.join(memory_kb, "topics")
    index_file = os.path.join(topics_dir, "_index.json")
    overview_file = os.path.join(memory_kb, "project", "project-overview.md")

    sections = []

    # 1. 模式說明
    sections.append("## 當前模式：一般對話（預設）")
    sections.append("")
    sections.append("你正在以「一般全方位 Agent」身份運作。")
    sections.append("如果使用者表達想啟動 PM 模式（如「啟動PM」「使用PM」「PM模式」等語意），")
    sections.append("請切換至 PM agent 的工作流程（見 .claude/agents/pm.md）。")
    sections.append("")

    # 2. 一般模式 SOP
    sections.append("### 一般模式 SOP（必須遵循）")
    sections.append("")
    sections.append("當使用者詢問專案狀態、進度、或想恢復上次對話時：")
    sections.append("1. 呼叫 `recent_activity(timeframe=\"7d\")`")
    sections.append("2. 從結果中找 permalink 含 `conversations/` 的**最新**筆記，用 `read_note` 讀取")
    sections.append("3. 同時檢查 `topics/_index.json` 中 status 為 `active` 的主題")
    sections.append("4. 若 `conversations/` 無結果，才讀 recent_activity 清單的第一筆")
    sections.append("")
    sections.append("⚠️ **不要**直接讀 `project/` 筆記來回答進度問題——那是 PM 模式的資料。")
    sections.append("")

    # 3. 檢查 Basic Memory 是否就緒
    if os.path.exists(overview_file):
        sections.append("### Basic Memory 已就緒")
        sections.append("")
        sections.append("記憶知識庫位於 `memory-kb/`，透過 MCP 工具操作。")
        sections.append("")
    else:
        sections.append("⚠️ 找不到 project-overview.md，請確認 Basic Memory 已設定")
        sections.append("")

    # 4. 顯示主題記憶選單
    if os.path.exists(index_file):
        with open(index_file, "r", encoding="utf-8") as f:
            index = json.load(f)

        active_topics = [t for t in index.get("topics", []) if t.get("status") == "active"]

        if active_topics:
            sections.append("### 進行中的主題記憶")
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
        sections.append("### 主題記憶")
        sections.append("目前沒有進行中的主題。對話中說「筆記」可建立新主題。")
        sections.append("")

    output = {
        "continue": True,
        "hookSpecificOutput": {
            "additionalContext": "\n".join(sections)
        }
    }
    print(json.dumps(output))

except Exception as e:
    print(json.dumps({"continue": True, "systemMessage": f"SessionStart Hook Error: {str(e)}"}))
' || echo '{"continue": true}'
