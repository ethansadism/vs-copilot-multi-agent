#!/bin/bash
# Multi-Agent System — 注入安裝腳本（用於現有專案）
# 用法：在你的專案目錄下執行
#   bash <(curl -fsSL https://raw.githubusercontent.com/ethansadism/vs-copilot-multi-agent/main/bootstrap.sh)
set -e

REPO_URL="https://github.com/ethansadism/vs-copilot-multi-agent.git"
MARKER_START="# >>> multi-agent-system (auto-inserted, do not edit this block) <<<"
MARKER_END="# <<< multi-agent-system end >>>"

# 偵測可用的 Python 指令（Windows 上可能是 py、python 或 python3）
PYTHON=""
for cmd in python3 python py; do
    if "$cmd" --version >/dev/null 2>&1; then
        PYTHON="$cmd"
        break
    fi
done

if [ -z "$PYTHON" ]; then
    echo "❌ 找不到 Python。請先安裝 Python 3.10+。"
    echo "   Windows: https://www.python.org/downloads/"
    echo "   macOS:   brew install python3"
    exit 1
fi

export PYTHON
echo "🐍 使用 Python: $PYTHON ($($PYTHON --version 2>&1))"

# 用當前目錄名稱作為 basic-memory 專案名（與 setup.sh 一致）
PROJECT_NAME="$(basename "$(pwd)")"

echo "=== Multi-Agent System Bootstrap ==="
echo ""

# 建立暫存目錄，下載框架
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

echo "📥 下載框架檔案..."
git clone --depth=1 --quiet "$REPO_URL" "$TMPDIR/framework"
echo "✅ 下載完成"
echo ""

SRC="$TMPDIR/framework"

# ── 1. .claude/agents/ 和 .claude/hooks/ ─────────────────────────────
# 這兩個目錄是框架核心，直接複製（覆蓋）
echo "🔧 複製 agents 和 hooks..."
mkdir -p .claude/agents .claude/hooks
cp -r "$SRC/.claude/agents/"* .claude/agents/
cp -r "$SRC/.claude/hooks/"*  .claude/hooks/
echo "✅ .claude/agents/ 和 .claude/hooks/ 已更新"

# ── 2. .claude/settings.json ─────────────────────────────────────────
# 合併 hooks 設定（不覆蓋現有設定）
echo ""
echo "🔧 合併 .claude/settings.json..."
if [ ! -f ".claude/settings.json" ]; then
    cp "$SRC/.claude/settings.json" .claude/settings.json
    echo "✅ .claude/settings.json 已建立"
else
    $PYTHON - <<PYEOF
import json, sys

with open(".claude/settings.json") as f:
    existing = json.load(f)

with open("$SRC/.claude/settings.json") as f:
    framework = json.load(f)

# 合併 hooks：保留現有 hooks，加入框架新增的
existing_hooks = existing.get("hooks", {})
framework_hooks = framework.get("hooks", {})

for event, entries in framework_hooks.items():
    if event not in existing_hooks:
        existing_hooks[event] = entries
    else:
        # 檢查是否已有相同 command，避免重複
        existing_cmds = {h.get("hooks", [{}])[0].get("command", "") for h in existing_hooks[event] if h.get("hooks")}
        for entry in entries:
            cmd = (entry.get("hooks") or [{}])[0].get("command", "")
            if cmd not in existing_cmds:
                existing_hooks[event].append(entry)

existing["hooks"] = existing_hooks
with open(".claude/settings.json", "w") as f:
    json.dump(existing, f, indent=2, ensure_ascii=False)
    f.write("\n")

print("✅ .claude/settings.json 已合併（保留現有設定）")
PYEOF
fi

# ── 3. CLAUDE.md ──────────────────────────────────────────────────────
# 不覆蓋，將多 agent 規則插入為獨立區段
echo ""
echo "🔧 處理 CLAUDE.md..."
if [ ! -f "CLAUDE.md" ]; then
    cp "$SRC/CLAUDE.md" CLAUDE.md
    echo "✅ CLAUDE.md 已建立"
elif grep -qF "$MARKER_START" CLAUDE.md; then
    # 已安裝過：更新區段內容
    $PYTHON - <<PYEOF
import re

with open("CLAUDE.md") as f:
    content = f.read()

with open("$SRC/CLAUDE.md") as f:
    new_rules = f.read().strip()

marker_start = "$MARKER_START"
marker_end   = "$MARKER_END"

header = (
    "> **[Multi-Agent Memory System — 自動安裝]**\n"
    "> 以下規則由 `bootstrap.sh` 注入，是 basic-memory 記憶系統的核心運作規則。\n"
    "> **請勿刪除此區塊**。PM 多 Agent 模式為可選功能，一般對話直接使用即可。\n"
)
block = f"\n{marker_start}\n{header}\n{new_rules}\n{marker_end}\n"

# 替換現有區段
pattern = re.compile(
    re.escape(marker_start) + r".*?" + re.escape(marker_end),
    re.DOTALL
)
content = pattern.sub(block.strip(), content)

with open("CLAUDE.md", "w") as f:
    f.write(content)

print("✅ CLAUDE.md 多 agent 區段已更新")
PYEOF
else
    # 首次安裝：附加區段
    {
        echo ""
        echo "$MARKER_START"
        echo "> **[Multi-Agent Memory System — 自動安裝]**"
        echo "> 以下規則由 \`bootstrap.sh\` 注入，是 basic-memory 記憶系統的核心運作規則。"
        echo "> **請勿刪除此區塊**。PM 多 Agent 模式為可選功能，一般對話直接使用即可。"
        echo ""
        cat "$SRC/CLAUDE.md"
        echo "$MARKER_END"
    } >> CLAUDE.md
    echo "✅ 多 agent 規則已附加至現有 CLAUDE.md"
fi

# ── 4. .github/agents/ 和 .github/hooks/ ─────────────────────────────
echo ""
echo "🔧 複製 .github/agents 和 .github/hooks..."
mkdir -p .github/agents .github/hooks
cp -r "$SRC/.github/agents/"*  .github/agents/
cp -r "$SRC/.github/hooks/"*   .github/hooks/
echo "✅ .github/agents/ 和 .github/hooks/ 已更新"

# ── 5. .github/copilot-instructions.md ───────────────────────────────
echo ""
echo "🔧 處理 .github/copilot-instructions.md..."
COPILOT_SRC="$SRC/.github/copilot-instructions.md"
COPILOT_DST=".github/copilot-instructions.md"

if [ ! -f "$COPILOT_DST" ]; then
    cp "$COPILOT_SRC" "$COPILOT_DST"
    echo "✅ copilot-instructions.md 已建立"
elif grep -qF "$MARKER_START" "$COPILOT_DST"; then
    $PYTHON - <<PYEOF
import re

with open("$COPILOT_DST") as f:
    content = f.read()
with open("$COPILOT_SRC") as f:
    new_rules = f.read().strip()

marker_start = "$MARKER_START"
marker_end   = "$MARKER_END"

header = (
    "> **[Multi-Agent Memory System — 自動安裝]**\n"
    "> 以下規則由 `bootstrap.sh` 注入，是 basic-memory 記憶系統的核心運作規則。\n"
    "> **請勿刪除此區塊**。PM 多 Agent 模式為可選功能，一般對話直接使用即可。\n"
)
block = f"{marker_start}\n{header}\n{new_rules}\n{marker_end}"

pattern = re.compile(
    re.escape(marker_start) + r".*?" + re.escape(marker_end),
    re.DOTALL
)
content = pattern.sub(block, content)

with open("$COPILOT_DST", "w") as f:
    f.write(content)
print("✅ copilot-instructions.md 多 agent 區段已更新")
PYEOF
else
    {
        echo ""
        echo "$MARKER_START"
        echo "> **[Multi-Agent Memory System — 自動安裝]**"
        echo "> 以下規則由 \`bootstrap.sh\` 注入，是 basic-memory 記憶系統的核心運作規則。"
        echo "> **請勿刪除此區塊**。PM 多 Agent 模式為可選功能，一般對話直接使用即可。"
        echo ""
        cat "$COPILOT_SRC"
        echo "$MARKER_END"
    } >> "$COPILOT_DST"
    echo "✅ 多 agent 規則已附加至現有 copilot-instructions.md"
fi

# ── 6. .vscode/mcp.json ──────────────────────────────────────────────
echo ""
echo "🔧 處理 .vscode/mcp.json..."
mkdir -p .vscode
if [ ! -f ".vscode/mcp.json" ]; then
    cp "$SRC/.vscode/mcp.json" .vscode/mcp.json
    echo "✅ .vscode/mcp.json 已建立"
else
    $PYTHON - <<PYEOF
import json

with open(".vscode/mcp.json") as f:
    existing = json.load(f)
with open("$SRC/.vscode/mcp.json") as f:
    framework = json.load(f)

existing_servers = existing.get("servers", {})
for name, cfg in framework.get("servers", {}).items():
    if name not in existing_servers:
        existing_servers[name] = cfg

existing["servers"] = existing_servers
with open(".vscode/mcp.json", "w") as f:
    json.dump(existing, f, indent=2, ensure_ascii=False)
    f.write("\n")
print("✅ .vscode/mcp.json 已合併（保留現有 servers）")
PYEOF
fi
# 替換 basic-memory project name（來源是 multi-agent-system，要換成目前專案名）
$PYTHON - <<PYEOF
import json, os

project_name = os.path.basename(os.getcwd())
for path in [".vscode/mcp.json"]:
    if not os.path.exists(path):
        continue
    with open(path) as f:
        data = json.load(f)
    for server in data.get("servers", {}).values():
        args = server.get("args", [])
        if "--project" in args:
            idx = args.index("--project")
            if idx + 1 < len(args) and args[idx + 1] == "multi-agent-system":
                args[idx + 1] = project_name
    with open(path, "w") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")

print(f"✅ .vscode/mcp.json --project 已設為 '{project_name}'")
PYEOF

# ── 7. .mcp.json（Claude Code MCP 設定）──────────────────────────────
echo ""
echo "🔧 處理 .mcp.json..."
if [ ! -f ".mcp.json" ]; then
    cp "$SRC/.mcp.json" .mcp.json
    echo "✅ .mcp.json 已建立"
else
    $PYTHON - <<PYEOF
import json

with open(".mcp.json") as f:
    existing = json.load(f)
with open("$SRC/.mcp.json") as f:
    framework = json.load(f)

for key in ["mcpServers", "servers"]:
    for name, cfg in framework.get(key, {}).items():
        existing.setdefault(key, {})[name] = existing.get(key, {}).get(name, cfg)

with open(".mcp.json", "w") as f:
    json.dump(existing, f, indent=2, ensure_ascii=False)
    f.write("\n")
print("✅ .mcp.json 已合併")
PYEOF
fi
# 替換 basic-memory project name
$PYTHON - <<PYEOF
import json, os

project_name = os.path.basename(os.getcwd())
for path in [".mcp.json"]:
    if not os.path.exists(path):
        continue
    with open(path) as f:
        data = json.load(f)
    for server in data.get("mcpServers", {}).values():
        args = server.get("args", [])
        if "--project" in args:
            idx = args.index("--project")
            if idx + 1 < len(args) and args[idx + 1] == "multi-agent-system":
                args[idx + 1] = project_name
    with open(path, "w") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")

print(f"✅ .mcp.json --project 已設為 '{project_name}'")
PYEOF

# ── 8. memory-kb 目錄結構 ─────────────────────────────────────────────
echo ""
echo "🔧 建立 memory-kb 目錄結構..."
for dir in memory-kb/conversations memory-kb/crawler memory-kb/database \
           memory-kb/frontend memory-kb/project memory-kb/topics; do
    mkdir -p "$dir"
    touch "$dir/.gitkeep"
done
echo "✅ memory-kb/ 結構已建立（內容不進 git）"

# ── 9. 寫入 kickoff note（讓第一個 agent 知道這裡發生了什麼）─────────────
echo ""
echo "📝 寫入 bootstrap kickoff note..."
BOOTSTRAP_DATE=$(date "+%Y-%m-%d %H:%M")
cat > "memory-kb/project/${PROJECT_NAME}_001_bootstrap-summary.md" <<NOTE
---
title: ${PROJECT_NAME}_001_bootstrap-summary
type: note
tags:
- app:${PROJECT_NAME}
- agent:claude
- type:session
---

# Bootstrap Summary — ${PROJECT_NAME}

此專案於 ${BOOTSTRAP_DATE} 透過 bootstrap.sh 安裝了 Multi-Agent Memory System。

## 已安裝的元件

- \`.claude/agents/\` — Agent 定義（PM / Crawler / Database / Frontend）
- \`.claude/hooks/\` — SessionStart / UserPromptSubmit hooks
- \`.claude/settings.json\` — Hook 設定（已與現有設定合併）
- \`CLAUDE.md\` — multi-agent 記憶規則（附加區塊，請勿刪除）
- \`.github/agents/\` + \`.github/hooks/\` — VS Code Copilot 支援
- \`.vscode/mcp.json\` + \`.mcp.json\` — basic-memory MCP 設定
- \`memory-kb/\` — 記憶知識庫（此筆記是第一筆）

## 使用方式

- **一般對話（預設）**：直接與 Claude Code 或 VS Code Copilot 對話即可
- **PM 多 Agent 模式**：說「啟動 PM」切換，PM 會協調多個 subagent 分工

## 記憶系統

- 知識存放於 \`memory-kb/\`，透過 basic-memory MCP 讀寫
- \`memory-kb/\` 內容不進 git（各人擁有自己的記憶庫）
- 說「筆記」或「記一下」可儲存當前對話重點

## Observations

- app :: ${PROJECT_NAME}
- agent :: claude
- type :: session
- bootstrapped :: ${BOOTSTRAP_DATE}
NOTE
echo "✅ kickoff note 已寫入 memory-kb/project/"

# ── 10. 掃描現有知識來源 ──────────────────────────────────────────────
echo ""
bash "$SRC/migrate-scan.sh"

# ── 11. 執行 setup.sh（basic-memory 安裝與註冊）───────────────────────
echo ""
echo "🚀 執行 setup.sh 安裝 basic-memory..."
bash "$SRC/setup.sh"

echo ""
echo "=== Bootstrap 完成 ==="
echo ""
echo "已安裝的內容："
echo "  .claude/agents/     — Agent 定義（PM / Crawler / Database / Frontend）"
echo "  .claude/hooks/      — Claude Code hooks"
echo "  .claude/settings.json — Hook 設定（已與現有設定合併）"
echo "  CLAUDE.md           — 多 agent 規則（附加於原有內容之後）"
echo "  .github/agents/     — VS Code Copilot agent 定義"
echo "  .github/hooks/      — VS Code Copilot hooks"
echo "  .vscode/mcp.json    — MCP 設定（已與現有設定合併）"
echo "  memory-kb/          — 空的記憶知識庫結構"
echo ""
echo "下一步："
echo "  【Claude Code】在此目錄執行 claude，開始對話"
echo "  【VS Code】開啟 Copilot Chat，Agent 選單選擇 'Project Manager'"
echo ""
SCAN_REPORT="memory-kb/project/${PROJECT_NAME}_002_migration-scan.md"
if [ -f "$SCAN_REPORT" ]; then
    echo "  📋 偵測到現有知識來源，輸入「使用MAS開始整理並初始化現有環境」啟動遷移引導"
fi
