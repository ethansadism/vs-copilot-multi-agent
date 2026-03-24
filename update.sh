#!/bin/bash
# Multi-Agent System — 更新腳本（只更新 hooks/agents/規則，不動設定和記憶）
# 用法：在已安裝的專案目錄下執行
#   bash <(curl -fsSL https://raw.githubusercontent.com/ethansadism/vs-copilot-multi-agent/main/update.sh)

set -e

REPO_URL="https://github.com/ethansadism/vs-copilot-multi-agent.git"
MARKER_START="# >>> multi-agent-system (auto-inserted, do not edit this block) <<<"
MARKER_END="# <<< multi-agent-system end >>>"

# ── 前置檢查 ──────────────────────────────────────────────────────────
if [ ! -d ".claude" ] && [ ! -d ".github/agents" ]; then
    echo "❌ 找不到 .claude/ 或 .github/agents/，請先用 bootstrap.sh 安裝。"
    exit 1
fi

# 偵測 Python
PYTHON=""
for cmd in python3 python py; do
    if "$cmd" --version >/dev/null 2>&1; then
        PYTHON="$cmd"
        break
    fi
done

if [ -z "$PYTHON" ]; then
    echo "❌ 找不到 Python。請先安裝 Python 3.10+。"
    exit 1
fi
export PYTHON

# Windows Git Bash 路徑轉換
if command -v cygpath >/dev/null 2>&1; then
    CWD_PY="$(cygpath -w "$(pwd)")"
else
    CWD_PY="$(pwd)"
fi

echo "=== Multi-Agent System Update ==="
echo "🐍 Python: $PYTHON ($($PYTHON --version 2>&1))"
echo ""

# 下載最新版本
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

echo "📥 下載最新版本..."
git clone --depth=1 --quiet "$REPO_URL" "$TMPDIR/framework"
SRC="$TMPDIR/framework"

if command -v cygpath >/dev/null 2>&1; then
    SRC_PY="$(cygpath -w "$SRC")"
else
    SRC_PY="$SRC"
fi

# 取得版本資訊
NEW_VERSION=$(grep -oP 'v[\d.]+' "$SRC/README.md" | head -1 || echo "unknown")
echo "✅ 最新版本: $NEW_VERSION"
echo ""

# ── 1. Hooks（核心更新項目）────────────────────────────────────────────
echo "🔧 更新 hooks..."
if [ -d ".claude/hooks" ]; then
    cp -r "$SRC/.claude/hooks/"* .claude/hooks/
    echo "  ✅ .claude/hooks/ 已更新"
fi
if [ -d ".github/hooks" ]; then
    cp -r "$SRC/.github/hooks/"* .github/hooks/
    echo "  ✅ .github/hooks/ 已更新"
fi

# ── 2. Agents 定義 ────────────────────────────────────────────────────
echo ""
echo "🔧 更新 agent 定義..."
if [ -d ".claude/agents" ]; then
    cp -r "$SRC/.claude/agents/"* .claude/agents/
    echo "  ✅ .claude/agents/ 已更新"
fi
if [ -d ".github/agents" ]; then
    cp -r "$SRC/.github/agents/"* .github/agents/
    echo "  ✅ .github/agents/ 已更新"
fi

# ── 3. settings.json — 合併新增的 hook 設定（不覆蓋現有）──────────────
echo ""
echo "🔧 合併 hook 設定..."
if [ -f ".claude/settings.json" ]; then
    $PYTHON - <<PYEOF
import json, os
os.chdir(r"$CWD_PY")

with open(".claude/settings.json") as f:
    existing = json.load(f)
with open(os.path.join(r"$SRC_PY", ".claude", "settings.json")) as f:
    framework = json.load(f)

existing_hooks = existing.get("hooks", {})
framework_hooks = framework.get("hooks", {})
added = 0

for event, entries in framework_hooks.items():
    if event not in existing_hooks:
        existing_hooks[event] = entries
        added += len(entries)
    else:
        existing_cmds = {h.get("hooks", [{}])[0].get("command", "") for h in existing_hooks[event] if h.get("hooks")}
        for entry in entries:
            cmd = (entry.get("hooks") or [{}])[0].get("command", "")
            if cmd not in existing_cmds:
                existing_hooks[event].append(entry)
                added += 1

existing["hooks"] = existing_hooks
with open(".claude/settings.json", "w") as f:
    json.dump(existing, f, indent=2, ensure_ascii=False)
    f.write("\n")

if added:
    print(f"  ✅ .claude/settings.json 新增 {added} 個 hook 設定")
else:
    print("  ✅ .claude/settings.json 無需更新")
PYEOF
fi

# ── 4. CLAUDE.md — 更新 marker 區塊（保留使用者自訂內容）──────────────
echo ""
echo "🔧 更新 CLAUDE.md 規則..."
if [ -f "CLAUDE.md" ] && grep -qF "$MARKER_START" CLAUDE.md; then
    $PYTHON - <<PYEOF
import re, os
os.chdir(r"$CWD_PY")

with open("CLAUDE.md") as f:
    content = f.read()
with open(os.path.join(r"$SRC_PY", "CLAUDE.md")) as f:
    new_rules = f.read().strip()

marker_start = "$MARKER_START"
marker_end   = "$MARKER_END"

header = (
    "> **[Multi-Agent Memory System — 自動安裝]**\n"
    "> 以下規則由 bootstrap.sh 注入，是 basic-memory 記憶系統的核心運作規則。\n"
    "> **請勿刪除此區塊**。PM 多 Agent 模式為可選功能，一般對話直接使用即可。\n"
)
block = f"\n{marker_start}\n{header}\n{new_rules}\n{marker_end}\n"

pattern = re.compile(
    re.escape(marker_start) + r".*?" + re.escape(marker_end),
    re.DOTALL
)
content = pattern.sub(block.strip(), content)

with open("CLAUDE.md", "w") as f:
    f.write(content)
print("  ✅ CLAUDE.md 規則區塊已更新")
PYEOF
else
    echo "  ⏭️  CLAUDE.md 無 marker 區塊，跳過（手動安裝的請重新執行 bootstrap.sh）"
fi

# ── 5. copilot-instructions.md — 更新 marker 區塊 ────────────────────
COPILOT_DST=".github/copilot-instructions.md"
if [ -f "$COPILOT_DST" ] && grep -qF "$MARKER_START" "$COPILOT_DST"; then
    $PYTHON - <<PYEOF
import re, os
os.chdir(r"$CWD_PY")

with open("$COPILOT_DST") as f:
    content = f.read()
with open(os.path.join(r"$SRC_PY", ".github", "copilot-instructions.md")) as f:
    new_rules = f.read().strip()

marker_start = "$MARKER_START"
marker_end   = "$MARKER_END"

header = (
    "> **[Multi-Agent Memory System — 自動安裝]**\n"
    "> 以下規則由 bootstrap.sh 注入，是 basic-memory 記憶系統的核心運作規則。\n"
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
print("  ✅ copilot-instructions.md 規則區塊已更新")
PYEOF
fi

# ── 完成 ──────────────────────────────────────────────────────────────
echo ""
echo "=== 更新完成 ==="
echo ""
echo "已更新："
echo "  ✅ .claude/hooks/      — Hook 腳本"
echo "  ✅ .claude/agents/     — Agent 定義"
echo "  ✅ .github/hooks/      — VS Code Copilot hooks"
echo "  ✅ .github/agents/     — VS Code Copilot agents"
echo "  ✅ settings.json       — 新增的 hook 設定（已合併）"
echo "  ✅ CLAUDE.md           — 規則區塊"
echo ""
echo "未變動："
echo "  ⏭️  memory-kb/         — 記憶資料（不受影響）"
echo "  ⏭️  .mcp.json          — MCP 設定（不受影響）"
echo "  ⏭️  .vscode/mcp.json   — MCP 設定（不受影響）"
echo ""
