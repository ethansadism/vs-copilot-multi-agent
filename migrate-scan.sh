#!/bin/bash
# Multi-Agent System — 現有專案知識掃描
# 掃描專案中可能存在的知識來源，產生結構化報告供 Claude 互動式遷移
# 用法：bootstrap.sh 結尾自動呼叫，或手動執行 bash migrate-scan.sh

set -e

PROJECT_NAME="$(basename "$(pwd)")"
REPORT_FILE="memory-kb/project/${PROJECT_NAME}_002_migration-scan.md"
SCAN_DATE=$(date "+%Y-%m-%d %H:%M")

# ── 掃描函式 ──────────────────────────────────────────────────────────

found_items=()

scan_file() {
    local path="$1"
    local category="$2"
    local description="$3"
    if [ -f "$path" ]; then
        local lines
        lines=$(wc -l < "$path" 2>/dev/null || echo "0")
        local size
        size=$(wc -c < "$path" 2>/dev/null || echo "0")
        found_items+=("| \`$path\` | $category | $description | ${lines} 行 / ${size} bytes |")
    fi
}

scan_dir() {
    local path="$1"
    local category="$2"
    local description="$3"
    if [ -d "$path" ]; then
        local count
        count=$(find "$path" -type f -name "*.md" 2>/dev/null | wc -l)
        if [ "$count" -gt 0 ]; then
            found_items+=("| \`$path/\` | $category | $description（${count} 個 .md 檔） | 目錄 |")
        fi
    fi
}

scan_glob() {
    local pattern="$1"
    local category="$2"
    local description="$3"
    local matches
    matches=$(find . -maxdepth 3 -name "$pattern" -not -path "./.git/*" -not -path "./node_modules/*" -not -path "./memory-kb/*" -not -path "./.claude/*" -not -path "./.github/*" 2>/dev/null || true)
    for f in $matches; do
        local lines
        lines=$(wc -l < "$f" 2>/dev/null || echo "0")
        found_items+=("| \`$f\` | $category | $description | ${lines} 行 |")
    done
}

echo "🔍 掃描現有專案知識來源..."
echo ""

# ── 1. AI 工具規則檔 ─────────────────────────────────────────────────
scan_file ".cursorrules"          "ai-rules"    "Cursor AI 規則"
scan_file ".cursor/rules"         "ai-rules"    "Cursor AI 規則（新格式）"
scan_file ".windsurfrules"        "ai-rules"    "Windsurf AI 規則"
scan_file "AGENTS.md"             "ai-rules"    "Codex / Agent 規則"
scan_file ".aider.conf.yml"       "ai-rules"    "Aider 設定"
scan_file ".aider.model.yml"      "ai-rules"    "Aider 模型設定"
scan_file ".continue/config.json" "ai-rules"    "Continue AI 設定"
scan_file "cline_docs/rules.md"   "ai-rules"    "Cline 規則"

# ── 2. 專案文件 ───────────────────────────────────────────────────────
scan_file "CONVENTIONS.md"        "project-doc" "程式碼慣例文件"
scan_file "CONTRIBUTING.md"       "project-doc" "貢獻指南"
scan_file "ARCHITECTURE.md"       "project-doc" "架構文件"
scan_file "TODO.md"               "project-doc" "待辦清單"
scan_file "CHANGELOG.md"          "project-doc" "變更紀錄"
scan_file "DESIGN.md"             "project-doc" "設計文件"
scan_file "DEVELOPMENT.md"        "project-doc" "開發指南"
scan_file "ADR.md"                "project-doc" "架構決策紀錄"

# ── 3. 文件目錄 ───────────────────────────────────────────────────────
scan_dir "docs"                   "docs-dir"    "文件目錄"
scan_dir "doc"                    "docs-dir"    "文件目錄"
scan_dir "wiki"                   "docs-dir"    "Wiki 目錄"
scan_dir ".ai"                    "docs-dir"    "AI 知識目錄"
scan_dir "notes"                  "docs-dir"    "筆記目錄"
scan_dir "adr"                    "docs-dir"    "架構決策紀錄目錄"
scan_dir "decisions"              "docs-dir"    "決策紀錄目錄"

# ── 4. 散落的 markdown 筆記 ──────────────────────────────────────────
# 排除 README.md / CLAUDE.md / LICENSE / 常見非知識檔
KNOWN_MD="README.md\|CLAUDE.md\|LICENSE.md\|CHANGELOG.md\|CONTRIBUTING.md\|CONVENTIONS.md\|ARCHITECTURE.md\|TODO.md\|DESIGN.md\|DEVELOPMENT.md\|ADR.md\|AGENTS.md"
OTHER_MD=$(find . -maxdepth 2 -name "*.md" -not -path "./.git/*" -not -path "./node_modules/*" -not -path "./memory-kb/*" -not -path "./.claude/*" -not -path "./.github/*" 2>/dev/null | grep -v "$KNOWN_MD" || true)
for f in $OTHER_MD; do
    local_lines=$(wc -l < "$f" 2>/dev/null || echo "0")
    if [ "$local_lines" -gt 5 ]; then
        found_items+=("| \`$f\` | other-md | 專案 Markdown 檔案 | ${local_lines} 行 |")
    fi
done

# ── 5. AI 對話匯出檔 ────────────────────────────────────────────────
scan_glob "*.chatgpt.json"        "ai-export"   "ChatGPT 匯出"
scan_glob "conversations.json"    "ai-export"   "AI 對話匯出"
scan_glob "*chat-history*"        "ai-export"   "對話歷史"

# ── 6. 現有記憶系統 ──────────────────────────────────────────────────
scan_dir ".memory"                "memory-sys"  "既有記憶系統"
scan_dir "knowledge"              "memory-sys"  "知識庫目錄"
scan_file ".claude/memory.json"   "memory-sys"  "Claude 記憶檔"

# ── 輸出結果 ─────────────────────────────────────────────────────────

TOTAL=${#found_items[@]}

if [ "$TOTAL" -eq 0 ]; then
    echo "✅ 掃描完成：未發現既有知識來源（乾淨的專案）"
    echo ""
    echo "你可以直接開始使用，記憶庫會隨開發自然成長。"
    # 不寫報告檔
    exit 0
fi

echo "📋 發現 ${TOTAL} 個潛在知識來源，寫入掃描報告..."

# 確保目錄存在
mkdir -p "$(dirname "$REPORT_FILE")"

cat > "$REPORT_FILE" <<HEADER
---
title: ${PROJECT_NAME}_002_migration-scan
type: note
tags:
- app:${PROJECT_NAME}
- agent:claude
- type:migration-scan
---

# Migration Scan Report — ${PROJECT_NAME}

掃描時間：${SCAN_DATE}
發現 **${TOTAL}** 個潛在知識來源。

## 發現的知識來源

| 路徑 | 分類 | 說明 | 大小 |
|------|------|------|------|
HEADER

for item in "${found_items[@]}"; do
    echo "$item" >> "$REPORT_FILE"
done

cat >> "$REPORT_FILE" <<'FOOTER'

## 分類說明

| 分類 | 說明 | 建議遷移到 |
|------|------|-----------|
| `ai-rules` | 其他 AI 工具的規則/設定 | 整合進 `CLAUDE.md` 或 `memory-kb/project/` |
| `project-doc` | 專案層級文件 | `memory-kb/project/` 或 `memory-kb/topics/` |
| `docs-dir` | 文件目錄 | 按內容分類到 `memory-kb/` 子目錄 |
| `other-md` | 散落的 Markdown | 視內容決定 |
| `ai-export` | AI 對話匯出 | 摘要後存入 `memory-kb/conversations/` |
| `memory-sys` | 既有記憶系統 | 整合進 `memory-kb/` |

## 下一步

啟動 Claude Code，輸入：

```
使用MAS開始整理並初始化現有環境
```

Claude 會讀取此報告，逐一詢問你如何處理每個發現的知識來源。

## Observations

- app :: ${PROJECT_NAME}
- agent :: claude
- type :: migration-scan
- scan_date :: ${SCAN_DATE}
- items_found :: ${TOTAL}
FOOTER

# 將 Observations 中的變數再替換一次（heredoc 內 single-quote 不展開）
sed -i "s/\${PROJECT_NAME}/$PROJECT_NAME/g; s/\${SCAN_DATE}/$SCAN_DATE/g; s/\${TOTAL}/$TOTAL/g" "$REPORT_FILE"

echo "✅ 掃描報告已寫入：${REPORT_FILE}"
echo ""
echo "下一步：啟動 Claude Code，輸入「使用MAS開始整理並初始化現有環境」"
echo "Claude 會讀取報告，逐一引導你遷移每個知識來源。"
