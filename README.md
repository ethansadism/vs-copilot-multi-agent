# Multi-Agent Collaboration System (v0.02)

基於 VS Code Copilot 的多 Agent 協作系統。PM 協調、專家執行、Basic Memory 知識圖譜持久化。

## 系統架構

### 四個 Agent 角色

| Agent | 職責 | 模型 | 記憶資料夾 |
|-------|------|------|-----------|
| **Project Manager** | 協調分工、記憶管理 | claude opus 4.6 | `project/` |
| **Crawler Expert** | 爬蟲開發、反爬蟲 | claude sonnet 4.6 | `crawler/` |
| **Database Expert** | 數據模型、遷移 | claude sonnet 4.6 | `database/` |
| **Frontend Engineer** | UI/UX、圖表 | claude sonnet 4.6 | `frontend/` |

### 核心機制

- **Basic Memory MCP** — 所有記憶以 Markdown 筆記存放，透過語意搜尋 (`search_notes`) 和知識圖譜 (`[[wiki-links]]`) 關聯
- **Subagent 編排** — PM 透過 `agents: ['*']` + `tools: ['agent']` 呼叫專家 agent
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
├── memory-kb/               # Basic Memory 知識庫（Markdown 筆記）
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
├── memory/                  # [舊版] JSON 記憶（保留供參考）
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
├── tools/                   # 工具管理
│   ├── TOOLS_MANIFEST.md    # 工具矩陣和 MCP 推薦
│   └── mcp-registry.json    # MCP 註冊表
│
├── reports/                 # Agent 任務報告
└── logs/                    # 審計日誌

.vscode/
└── mcp.json                 # Basic Memory MCP 伺服器設定
```

## 快速開始

### 前置需求

1. **uv** — Python 套件管理器
2. **Basic Memory** — `uv tool install basic-memory`
3. 建立專案：`basic-memory project add multi-agent-system ".github/memory-kb"`

### 1. 打開項目

```bash
code /path/to/this/project
```

VS Code 會自動：
- 掃描 `.github/agents/` 載入所有 Agent
- 從 `.github/hooks/hooks.json` 載入 Hook 配置
- 從 `.vscode/mcp.json` 啟動 Basic Memory MCP 伺服器

### 2. 與 PM 對話

1. 打開 Copilot Chat（`Ctrl+L`）
2. 在 Agents 下拉菜單中選擇 **Project Manager**
3. 提交需求，例如：

```
我需要爬取 Dcard 股票版的數據，設計儲存模型，然後做一個 Dashboard 顯示前 10 支熱門股票。
```

### 3. PM 的標準工作流程

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

**版本**: 0.021
**上次更新**: 2026-03-17
