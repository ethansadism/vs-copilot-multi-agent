# Multi-Agent Collaboration System (v0.07)

基於 **VS Code Copilot** 和 **Claude Code** 的多 Agent 協作系統。PM 協調、專家執行、Basic Memory 知識圖譜持久化。

> 兩套平台共用相同的架構理念和記憶格式，可依環境選擇使用。

## 快速開始

### 前置需求

- Python 3.10+（用於 Hook 腳本）
- [basic-memory](https://github.com/basicmachines-co/basic-memory) MCP 伺服器

**VS Code Copilot 版本**另需：
- [VS Code](https://code.visualstudio.com/) 1.99+
- [GitHub Copilot](https://marketplace.visualstudio.com/items?itemName=GitHub.copilot) 訂閱（需支援 Custom Agents）

**Claude Code 版本**另需：
- [Claude Code](https://claude.ai/code) CLI

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

### 使用

**VS Code Copilot：**
1. 用 VS Code 開啟專案
2. 開啟 Copilot Chat（`Cmd+L` / `Ctrl+L`）
3. 在 Agent 下拉菜單選擇 **Project Manager**
4. 跟 PM 提需求

**Claude Code：**
1. 在專案目錄執行 `claude`
2. SessionStart hook 自動顯示主題記憶選單
3. 直接對話或選擇 PM agent 開始工作

## 系統架構

### 四個 Agent 角色

| Agent | 職責 | 模型 | 記憶資料夾 |
|-------|------|------|-----------|
| **Project Manager** | 協調分工、記憶管理 | Opus | `project/` |
| **Crawler Expert** | 爬蟲開發、反爬蟲 | Sonnet | `crawler/` |
| **Database Expert** | 數據模型、遷移 | Sonnet | `database/` |
| **Frontend Engineer** | UI/UX、圖表 | Sonnet | `frontend/` |

### 核心機制

- **Basic Memory MCP** — 所有記憶以 Markdown 筆記存放，透過語意搜尋 (`search_notes`) 和知識圖譜 (`[[wiki-links]]`) 關聯
- **Subagent 編排** — PM 協調專家 agent 並行或依序執行任務
- **介面契約傳遞** — PM 在 `contracts/` 建立合約筆記，確保跨 agent 介面一致
- **記憶自動提示** — SessionStart Hook 提醒 agent 用 `search_notes` 查詢記憶
- **記憶更新強制** — Subagent Stop Hook 檢查記憶是否更新，未更新則阻擋
- **長對話保護** — PreCompact Hook 在 context 壓縮前重新注入關鍵資訊
- **主題記憶** — 對話可依主題分類儲存，封存後不自動載入（節省 token）

## 雙平台結構

```
根目錄/
├── CLAUDE.md                    # Claude Code 全域規則
├── .mcp.json                    # Claude Code MCP 設定
│
├── .claude/                     # === Claude Code 版本 ===
│   ├── agents/                  # Agent 定義
│   │   ├── pm.md                # PM（Opus，頂層協調者）
│   │   ├── crawler.md           # 爬蟲專家（Sonnet）
│   │   ├── database.md          # 資料庫專家（Sonnet）
│   │   └── frontend.md          # 前端工程師（Sonnet）
│   ├── hooks/                   # 8 個 Hook 腳本
│   │   ├── session-init.sh      # SessionStart：主題選單 + 記憶提示
│   │   ├── user-prompt-submit.sh # UserPromptSubmit：關鍵字偵測 + 審計
│   │   ├── subagent-start.sh    # SubagentStart：注入記憶提示
│   │   ├── subagent-memory-check.sh # Per-agent Stop：記憶更新阻擋
│   │   ├── post-tool-use.sh     # PostToolUse：工具使用審計
│   │   ├── pre-compact.sh       # PreCompact：壓縮前保護 + 儲存提醒
│   │   ├── stop.sh              # Stop：記憶更新提醒
│   │   └── validate-write-note.sh # PreToolUse：tags 格式驗證（阻擋）
│   ├── settings.json            # Hook 配置
│   └── memory-kb/               # 記憶知識庫
│       ├── contracts/
│       ├── conversations/
│       ├── project/
│       ├── crawler/
│       ├── database/
│       ├── frontend/
│       └── topics/              # 主題記憶
│           └── _index.json      # 主題索引
│
├── .github/                     # === VS Code Copilot 版本 ===
│   ├── agents/                  # .agent.md 格式
│   ├── copilot-instructions.md  # 全域規則
│   ├── hooks/                   # hooks.json + 腳本
│   └── memory-kb/               # 記憶知識庫
│
└── .vscode/
    └── mcp.json                 # VS Code MCP 設定
```

## Hook 系統

### Claude Code 版本（8 個 Hook）

| Hook Event | 腳本 | 機制 |
|------------|------|------|
| **SessionStart** | session-init.sh | 顯示主題選單 + 記憶提示 |
| **UserPromptSubmit** | user-prompt-submit.sh | 關鍵字偵測「筆記」→ 注入儲存提示 |
| **SubagentStart** | subagent-start.sh | 注入 folder 路徑 + 筆記列表 + 時間戳 |
| **Per-agent Stop** | subagent-memory-check.sh | **exit 2 阻擋**未寫記憶的 subagent |
| **PostToolUse** | post-tool-use.sh | 工具使用審計日誌 |
| **PreCompact** | pre-compact.sh | 專案摘要 + 主題記憶儲存提醒 |
| **Stop** | stop.sh | 記憶更新提醒 |
| **PreToolUse** | validate-write-note.sh | 驗證 write_note tags（exit 2 阻擋） |

### VS Code Copilot 版本（7 個 Hook）

| Hook Event | 腳本 | 機制 |
|------------|------|------|
| **SessionStart** | session-init.sh | 記憶提示 |
| **UserPromptSubmit** | log-prompt.sh | 審計日誌 |
| **SubagentStart** | subagent-start.sh | 注入記憶提示 + 時間戳 |
| **SubagentStop** | subagent-stop.sh | 記憶更新偵測（警告） |
| **PostToolUse** | post-tool-use.sh | 工具使用審計 |
| **PreCompact** | pre-compact.sh | 專案摘要注入 |
| **Stop** | stop.sh | 記憶更新提醒 |

## 主題記憶系統（Claude Code 新增）

對話可依主題分類儲存，方便跨 session 延續。

- **建立**：說「筆記」「記錄進度」等關鍵字觸發
- **選擇**：SessionStart 自動顯示進行中主題
- **封存**：說「封存 {主題名}」，封存後不再自動載入
- **載入**：選擇主題後才載入該主題筆記（按需載入）

## 記憶系統：Basic Memory

所有記憶以 **Markdown 筆記** 存放，透過 [Basic Memory](https://github.com/basicmachines-co/basic-memory) MCP 伺服器提供語意搜尋和知識圖譜功能。

| 工具 | 用途 |
|------|------|
| `search_notes` | 語意搜尋筆記（最常用）|
| `read_note` | 用 permalink 讀取特定筆記 |
| `write_note` | 建立或更新筆記 |
| `build_context` | 從多個筆記建構上下文 |
| `recent_activity` | 查看最近的記憶變更 |

## 參考資源

- [VS Code Copilot Custom Agents](https://code.visualstudio.com/docs/copilot/customization/custom-agents)
- [VS Code Copilot Hooks](https://code.visualstudio.com/docs/copilot/customization/hooks)
- [Claude Code Hooks](https://docs.anthropic.com/en/docs/claude-code/hooks)
- [Model Context Protocol (MCP)](https://modelcontextprotocol.io/)

---

**版本**: 0.07
**上次更新**: 2026-03-20
