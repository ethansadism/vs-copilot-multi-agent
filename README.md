# Multi-Agent Collaboration System (v0.05)

基於 VS Code Copilot 的多 Agent 協作系統。PM 協調、專家執行、Basic Memory 知識圖譜持久化。

> **Clone → `bash setup.sh` → 打開 VS Code → 選擇 PM agent → 開始對話**

## 快速開始

### 前置需求

- [VS Code](https://code.visualstudio.com/) 1.99+
- [GitHub Copilot](https://marketplace.visualstudio.com/items?itemName=GitHub.copilot) 訂閱（需支援 Custom Agents）
- Python 3.10+（用於 Hook 腳本和 Demo App）

### 安裝

```bash
git clone https://github.com/ethansadism/vs-copilot-multi-agent.git
cd vs-copilot-multi-agent
bash setup.sh
```

`setup.sh` 會自動：
1. 安裝 [uv](https://github.com/astral-sh/uv)（如未安裝）
2. 安裝 [basic-memory](https://github.com/basicmachines-co/basic-memory) MCP 伺服器
3. 註冊知識庫專案並同步索引
4. 建立 Python venv

> **⚠️ VS Code 可能找不到 `uvx`**：如果 MCP 伺服器啟動失敗，將 `.vscode/mcp.json` 中的 `"command": "uvx"` 改為完整路徑（如 `"/Users/你/.local/bin/uvx"`）。`setup.sh` 會提示實際路徑。

### 使用

1. 用 VS Code 開啟專案
2. 開啟 Copilot Chat（`Cmd+L` / `Ctrl+L`）
3. 在 Agent 下拉菜單選擇 **Project Manager**
4. 跟 PM 提需求，它會自動協調專家 Agent 完成任務

## 系統架構

### 四個 Agent 角色

| Agent | 職責 | 模型 | 記憶資料夾 |
|-------|------|------|-----------|
| **Project Manager** | 協調分工、記憶管理 | claude opus 4.6 | `project/` |
| **Crawler Expert** | 爬蟲開發、反爬蟲 | claude sonnet 4.6 | `crawler/` |
| **Database Expert** | 數據模型、遷移 | claude sonnet 4.6 | `database/` |
| **Frontend Engineer** | UI/UX、圖表 | claude sonnet 4.6 | `frontend/` |

> **模型名稱**取決於你的 Copilot 方案。請在 VS Code 模型選擇器中確認可用模型，並修改各 `.agent.md` 的 `model` 欄位。

### 核心機制

- **Basic Memory MCP** — 所有記憶以 Markdown 筆記存放，透過語意搜尋 (`search_notes`) 和知識圖譜 (`[[wiki-links]]`) 關聯
- **Subagent 編排** — PM 透過 `agents: ['*']` + `tools: ['agent']` 呼叫專家 agent
- **介面契約傳遞** — PM 在分派有依賴的任務時，將上游 agent 的函式簽名/回傳格式寫入下游任務描述，並在 `contracts/` 資料夾建立合約筆記供所有 agent 查閱
- **記憶自動提示** — SessionStart Hook 提醒 agent 用 `search_notes` 查詢記憶
- **記憶更新檢查** — Stop Hook 在會話結束前檢查記憶筆記是否已更新
- **長對話保護** — PreCompact Hook 在 context 壓縮前重新注入關鍵資訊

## 項目結構

```
.github/
├── agents/                  # Agent 定義（VS Code Copilot .agent.md 格式）
│   ├── pm.agent.md          # PM：agents=['*'], 頂層協調者
│   ├── crawler.agent.md     # 爬蟲專家
│   ├── database.agent.md    # 資料庫專家
│   └── frontend.agent.md    # 前端工程師
│
├── copilot-instructions.md  # 全域 Copilot 規則與對話開始 SOP（自動載入）
│
├── memory-kb/               # Basic Memory 知識庫（Markdown 筆記）
│   ├── contracts/       # 跨 agent 介面合約（PM 寫入，所有 agent 可讀）
│   ├── conversations/       # 跨角色重要對話紀錄（架構決策、重要會話摘要）
│   ├── project/             # PM 管理的全局筆記
│   │   ├── project-overview.md    # 專案狀態、技術棧
│   │   └── known-issues.md        # 已知問題追蹤
│   ├── crawler/             # 爬蟲經驗
│   │   ├── best-practices.md      # 最佳實踐與工具
│   │   ├── twse-api-ssl-fallback.md
│   │   ├── proxy-ip-block.md
│   │   └── ...
│   ├── database/            # 資料庫經驗
│   │   ├── stock-data-models.md
│   │   ├── sqlite-patterns.md
│   │   └── ...
│   └── frontend/            # 前端經驗
│       ├── dashboard-design-system.md
│       ├── stock-monitoring-ui.md
│       └── ...
│
├── hooks/                   # 7 個生命週期 Hook
│   ├── hooks.json           # Hook 配置
│   ├── session-init.*       # SessionStart：提醒查詢 Basic Memory
│   ├── log-prompt.*         # UserPromptSubmit：審計日誌
│   ├── subagent-start.*     # SubagentStart：注入 agent 記憶提示
│   ├── subagent-stop.*      # SubagentStop：記錄完成事件
│   ├── post-tool-use.*      # PostToolUse：記錄工具使用
│   ├── pre-compact.*        # PreCompact：壓縮前保護記憶
│   └── stop.*               # Stop：提醒更新記憶
│
├── reports/                 # Agent 任務報告
└── logs/                    # 審計日誌

.vscode/
└── mcp.json                 # Basic Memory MCP 伺服器設定
```

## PM 的標準工作流程

```
SessionStart Hook 提醒使用 search_notes
  ↓
PM 用 search_notes 查詢專案背景和已知問題
  ↓
PM 分析需求，提出計劃（調用哪些 agent、為什麼）
  ↓
你確認計劃 ✓
  ↓
PM 並行調用 Subagents（各 agent 用 search_notes 載入記憶）
  ↓
Subagents 各自：執行 → 測試 → 寫報告 → 用 write_note 更新記憶
  ↓
PM 收集報告，整合結果，用 write_note 更新全局記憶
  ↓
PM 向你報告完成狀態
  ↓
Stop Hook 檢查記憶是否已更新
```

## 記憶系統：Basic Memory

### 核心概念

所有記憶以 **Markdown 筆記** 存放在 `.github/memory-kb/`，透過 [Basic Memory](https://github.com/basicmachines-co/basic-memory) MCP 伺服器提供語意搜尋和知識圖譜功能。

筆記使用 `- key :: value` 語法記錄知識原子（Observations），用 `[[wiki-links]]` 建立筆記間的關聯（Relations）。

### MCP 工具

| 工具 | 用途 |
|------|------|
| `search_notes` | 語意搜尋筆記（最常用）|
| `read_note` | 用 permalink 讀取特定筆記 |
| `write_note` | 建立或更新筆記 |
| `build_context` | 從多個筆記建構上下文 |
| `recent_activity` | 查看最近的記憶變更 |

### 記憶更新時機

| Hook | 動作 |
|------|------|
| SessionStart | 提醒 agent 用 `search_notes` 查詢記憶 |
| SubagentStart | 提醒 subagent 搜尋其專屬記憶 |
| PreCompact | context 壓縮前重新注入記憶提示 |
| Stop | 提醒用 `write_note` 更新記憶 |

### 問題記錄格式

所有 agent 遇到問題修復後必須用 `write_note` 記錄：

```markdown
# 問題簡述

## Problem

- problem_id :: CRAWLER-XXX
- error_message :: 實際的錯誤訊息
- root_cause :: 根本原因分析

## Solution

- solution :: 解決方案
- prevention :: 防止再犯措施
```

## 模型配置

`model` 欄位指定使用的模型名稱（字串）：

```yaml
# PM — 需要推理能力
model: "claude opus 4.6"

# 專家 agent — 快速高效
model: "claude sonnet 4.6"
```

**注意**：模型名稱取決於你的 Copilot 方案。請在 VS Code 模型選擇器中查看可用模型，並修改各 `.agent.md` 的 `model` 欄位。

## 監控和調試

- **Hook 日誌**：View → Output → 選擇 "GitHub Copilot Chat Hooks"
- **工具使用記錄**：`.github/logs/tool-usage-YYYY-MM-DD.log`
- **用戶提示記錄**：`.github/logs/prompts-YYYY-MM-DD.log`
- **Agent 報告**：`.github/reports/`

## 參考資源

- [VS Code Copilot Custom Agents](https://code.visualstudio.com/docs/copilot/customization/custom-agents)
- [VS Code Copilot Hooks](https://code.visualstudio.com/docs/copilot/customization/hooks)
- [Model Context Protocol (MCP)](https://modelcontextprotocol.io/)

---

**版本**: 0.05
**上次更新**: 2026-03-18
