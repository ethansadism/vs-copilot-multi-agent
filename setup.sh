#!/bin/bash
# Multi-Agent System — 快速安裝腳本
# 用法：bash setup.sh
set -e

echo "=== Multi-Agent Collaboration System 安裝 ==="
echo ""

# 1. 檢查 uv
if ! command -v uv &> /dev/null && ! command -v uvx &> /dev/null; then
    echo "📦 安裝 uv（Python 套件管理器）..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
    echo "✅ uv 已安裝"
else
    echo "✅ uv 已存在"
fi

# 2. 安裝 basic-memory
if ! uvx basic-memory --version &> /dev/null 2>&1; then
    echo "📦 安裝 basic-memory..."
    uv tool install basic-memory
    echo "✅ basic-memory 已安裝"
else
    echo "✅ basic-memory 已存在"
fi

# 3. 註冊 Basic Memory 專案
# 用資料夾名稱作為專案名，避免跨專案衝突
PROJECT_NAME="$(basename "$(pwd)")"
KB_PATH=".claude/memory-kb"

echo ""
echo "📁 註冊 Basic Memory 專案 '$PROJECT_NAME'..."
# basic-memory project add 如果已存在會報錯，忽略
uvx basic-memory project add "$PROJECT_NAME" "$KB_PATH" 2>/dev/null || true
echo "✅ 專案 '$PROJECT_NAME' → $KB_PATH"

# 4. 重建索引
echo ""
echo "🔄 重建知識庫索引..."
uvx basic-memory reindex --project "$PROJECT_NAME"
echo "✅ 索引重建完成"

# 5. 檢查 uvx 路徑（VS Code 可能找不到 PATH 裡的 uvx）
UVX_PATH=$(which uvx 2>/dev/null || echo "")
if [ -z "$UVX_PATH" ]; then
    echo ""
    echo "⚠️  找不到 uvx 路徑。請手動更新 .vscode/mcp.json 中的 command 為完整路徑。"
else
    echo ""
    echo "📍 uvx 路徑：$UVX_PATH"
    # 如果 uvx 不在標準 PATH（/usr/local/bin 等），提示使用者
    case "$UVX_PATH" in
        /usr/local/bin/*|/usr/bin/*|/opt/homebrew/bin/*)
            echo "✅ uvx 在標準 PATH 中，.vscode/mcp.json 無需修改"
            ;;
        *)
            echo "⚠️  uvx 路徑非標準位置。如果 VS Code 啟動 MCP 失敗，請更新 .vscode/mcp.json："
            echo "   將 \"command\": \"uvx\" 改為 \"command\": \"$UVX_PATH\""
            ;;
    esac
fi

# 6. Python venv（可選，用於運行 demo app）
echo ""
if [ ! -d ".venv" ]; then
    echo "🐍 建立 Python venv..."
    python3 -m venv .venv
    echo "✅ venv 已建立（啟用：source .venv/bin/activate）"
else
    echo "✅ .venv 已存在"
fi

echo ""
echo "=== 安裝完成 ==="
echo ""
echo "下一步："
echo ""
echo "  【Claude Code】"
echo "  1. 在此目錄執行 claude"
echo "  2. 開始對話！（CLAUDE.md + hooks 會自動載入）"
echo ""
echo "  【VS Code Copilot】"
echo "  1. 用 VS Code 開啟此專案"
echo "  2. 開啟 Copilot Chat（Ctrl+L / Cmd+L）"
echo "  3. 在 Agent 下拉菜單選擇 'Project Manager'"
echo "  4. 開始對話！"
