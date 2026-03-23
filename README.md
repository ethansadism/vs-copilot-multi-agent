# Multi-Agent Collaboration System (v0.10)

基於 **VS Code Copilot** 和 **Claude Code** 的多 Agent 協作系統。PM 協調、專家執行、Basic Memory 知識圖譜持久化。

> 兩套平台共用相同的架構理念和記憶格式，可依環境選擇使用。

## 快速開始

### 前置需求

- Python 3.10+（用於 Hook 腳本）
- [basic-memory](https://github.com/basicmachines-co/basic-memory) MCP 伺服器
- **Windows**：[Git for Windows](https://git-scm.com/download/win)（bootstrap 腳本需要 Git Bash）

**VS Code Copilot 版本**另需：
- [VS Code](https://code.visualstudio.com/) 1.99+
- [GitHub Copilot](https://marketplace.visualstudio.com/items?itemName=GitHub.copilot) 訂閱（需支援 Custom Agents）

**Claude Code 版本**另需：
- [Claude Code](https://claude.ai/code) CLI

### 安裝

**方式一：注入現有專案（推薦）**

在你的專案目錄下執行：

| 環境 | 指令 |
|------|------|
| **macOS / Linux** | `bash <(curl -fsSL https://raw.githubusercontent.com/ethansadism/vs-copilot-multi-agent/main/bootstrap.sh)` |
| **Windows** | 在專案資料夾按右鍵 → **Open Git Bash here**，然後執行上面同一行指令 |

> **Windows 注意**：bootstrap 是 bash 腳本，需要透過 **Git Bash** 執行（安裝 [Git for Windows](https://git-scm.com/download/win) 即附帶）。PowerShell / CMD 不支援。

`bootstrap.sh` 會：
- 複製 `agents/`、`hooks/` 到 `.claude/` 和 `.github/`
- **合併**（不覆蓋）`settings.json`、`.vscode/mcp.json`
- **附加**（不覆蓋）`CLAUDE.md`、`copilot-instructions.md`
- 建立空的 `memory-kb/` 結構

> 現有專案的規則和設定不會被覆蓋。

**方式二：全新專案**

```bash
git clone https://github.com/ethansadism/vs-copilot-multi-agent.git my-project
cd my-project
bash setup.sh
```

> Demo app 範例（mta_demo 系列）在 [`examples` 分支](https://github.com/ethansadism/vs-copilot-multi-agent/tree/examples)。

### 使用

**VS Code Copilot：**
1. 用 VS Code 開啟專案
2. 開啟 Copilot Chat（`Cmd+L` / `Ctrl+L`）
3. 在 Agent 下拉菜單選擇 **Project Manager**
4. 跟 PM 提需求

**Claude Code：**
1. 在專案目錄執行 `claude`
2. SessionStart hook 自動顯示主題記憶選單
3. 預設為**一般對話模式**——直接與 Claude 對話、寫程式、解決問題
4. 需要多 Agent 協作時，說「啟動 PM」「PM 模式」等切換至 PM 模式

---

## 使用情境

### 雙模式概念

Claude Code 預設為**一般對話模式**，你可以直接與 Claude 對話。需要多 Agent 協作時，用自然語言切換至 PM 模式（不需要精確關鍵字）：

| 模式 | 啟動方式 | 用途 |
|------|---------|------|
| **一般對話**（預設） | 直接對話 | 寫程式、Debug、問問題、一般開發 |
| **PM 多 Agent** | 「啟動 PM」「PM 模式」「用 PM」等 | 多領域協作（爬蟲+DB+前端） |

### 日常操作

| 情境 | 你說 | 系統行為 |
|------|------|---------|
| **恢復上次進度** | 「繼續」「上次做到哪」 | 搜尋 `conversations/` 最新筆記 + 載入 active 主題 |
| **儲存對話為主題** | 「筆記」「記一下」「save」 | 詢問主題名稱 → 寫入 `topics/{topic-name}/` |
| **繼續某個主題** | 「載入 xxx 主題」或選單選號碼 | 讀取該主題所有筆記，恢復上下文 |
| **PM 多 agent 協作** | 「啟動 PM，建一個 Dashboard」 | PM 查記憶 → 建合約 → 派 Crawler/DB/Frontend |
| **封存完成的主題** | 「封存 xxx」 | 狀態改 `archived`，不再自動載入 |

> **注意**：一般模式從 `conversations/`（對話紀錄）恢復進度，不是 `project/`（PM 架構筆記）。這是刻意設計——一般模式關心「上次聊到哪」，PM 模式才用專案總覽。

### 在現有專案導入此系統

執行 `bootstrap.sh` 後，你的專案就有了完整的多 agent + 記憶系統。但**空的記憶庫不等於有用的記憶庫**——你需要把現有知識遷移進來。

#### Step 1：執行 bootstrap

```bash
cd your-project
bash <(curl -fsSL https://raw.githubusercontent.com/ethansadism/vs-copilot-multi-agent/main/bootstrap.sh)
```

> **Windows**：在專案資料夾按右鍵 → **Open Git Bash here**，然後執行上面指令。需要 [Git for Windows](https://git-scm.com/download/win)。

Bootstrap 自動產生一筆 kickoff note（`memory-kb/project/{project}_001_bootstrap-summary.md`），讓第一個 agent 就能理解環境。

#### Step 2：遷移現有知識到記憶庫

你可能已經有散落在各處的專案知識——其他 AI 的對話紀錄、個人筆記、markdown 文件、設計文件等。以下是將它們整理進系統的方式：

| 來源 | 遷移方式 | 存放位置 |
|------|---------|---------|
| **其他 AI 對話紀錄**（ChatGPT / Copilot / Gemini） | 匯出對話 → 貼給 Claude，說「把這段整理成筆記」 | `memory-kb/` 對應資料夾 |
| **現有 .md 筆記** | 直接放入 `memory-kb/` 對應資料夾，補上 frontmatter（title / tags） | 依內容分類 |
| **腦中的架構知識** | 口述給 Claude，說「筆記一下」觸發儲存流程 | `topics/` 或對應資料夾 |
| **設計文件 / PRD** | 貼給 Claude，請 PM 模式讀取並建立專案筆記 | `project/` |
| **已有的 CLAUDE.md 規則** | bootstrap 會自動附加（不覆蓋），兩套規則共存 | `CLAUDE.md` |

**遷移 .md 檔案的 frontmatter 範例：**

```markdown
---
title: myapp_001_api-design-notes
type: note
tags:
- app:myapp
- agent:claude
- type:reference
---

# API 設計筆記

（你的原有筆記內容...）

## Observations

- app :: myapp
- agent :: claude
```

> **提示**：不需要一次全部遷移。推薦的節奏是——bootstrap 後先正常開發，遇到需要上下文的情境時，再把相關知識整理進記憶庫。讓記憶隨著實際需求自然成長。

#### Step 3：用 reindex 建立語意索引

```bash
basic-memory reindex --project your-project
```

放入 `memory-kb/` 的 .md 檔案需要 reindex 才會被 `search_notes` 搜到。bootstrap 結尾的 `setup.sh` 會自動執行一次，但手動新增檔案後需要再跑一次。

#### Step 4：驗證

```
你：繼續
```

如果一切正常，Claude 會讀到 kickoff note 和你遷移的筆記，並展示目前的專案狀態。

### 新環境 / 換電腦

| 步驟 | 說明 |
|------|------|
| 1. `git pull` | 記憶庫（`memory-kb/`）跟著 repo 同步 |
| 2. 確認 basic-memory 已安裝 | `pip install basic-memory` 或用 `setup.sh` |
| 3. `basic-memory reindex` | 重建語意索引（本機儲存，不進 git） |
| 4. 啟動 `claude` | SessionStart hook 自動顯示主題選單 |
| 5. 說「繼續」 | 從 `conversations/` 恢復上次進度 |

> **注意**：Claude Code 的對話記錄（chat history）是**本機儲存**的，不跨電腦。跨裝置的知識延續完全靠 `memory-kb/` + git。

---

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
├── memory-kb/                   # === 共用記憶知識庫（兩平台共用）===
│   ├── contracts/               # 跨 agent 介面合約
│   ├── conversations/           # 重要對話紀錄
│   ├── project/                 # 專案狀態（PM 維護）
│   ├── crawler/                 # 爬蟲經驗
│   ├── database/                # 資料庫經驗
│   ├── frontend/                # UI/UX 經驗
│   └── topics/                  # 主題記憶
│       └── _index.json          # 主題索引
│
├── .claude/                     # === Claude Code 平台 ===
│   ├── agents/                  # Agent 定義
│   │   ├── pm.md                # PM（Opus，頂層協調者）
│   │   ├── crawler.md           # 爬蟲專家（Sonnet）
│   │   ├── database.md          # 資料庫專家（Sonnet）
│   │   └── frontend.md          # 前端工程師（Sonnet）
│   ├── hooks/                   # 8 個 Hook 腳本
│   └── settings.json            # Hook 配置
│
├── .github/                     # === VS Code Copilot 平台 ===
│   ├── agents/                  # .agent.md 格式
│   ├── copilot-instructions.md  # 全域規則
│   └── hooks/                   # hooks.json + 腳本
│
└── .vscode/
    └── mcp.json                 # VS Code MCP 設定
```

## Hook 系統

### Claude Code 版本（8 個 Hook）

| Hook Event | 腳本 | 機制 |
|------------|------|------|
| **SessionStart** | session-init.sh | 顯示主題選單 + 雙模式 SOP 提示 |
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

**版本**: 0.10
**上次更新**: 2026-03-23
