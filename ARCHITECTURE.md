# 系統架構說明（v0.04 — Basic Memory）

## 架構設計

```
┌─────────────────────────────────────────────────────────────┐
│                      VS Code Copilot                         │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                   用戶對話界面                        │   │
│  │                                                      │   │
│  │  Agents 下拉菜單 → [PM | Crawler | DB | Frontend] │   │
│  └──────────────────────────────────────────────────────┘   │
│                           ↓                                   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │          Project Manager（頂層協調者）                │   │
│  │          model: claude opus 4.6                       │   │
│  │          agents: ['*']  ← 可呼叫所有 subagent       │   │
│  │          tools: ['agent','basic-memory/*',...]       │   │
│  │                                                      │   │
│  │  • search_notes → 分析需求 → 提計劃 → 等確認 → 分工│   │
│  └──────────────────────────────────────────────────────┘   │
│         ↓ (subagent)       ↓ (subagent)      ↓ (subagent)   │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │
│  │  Crawler    │  │  Database   │  │  Frontend   │          │
│  │   Expert    │  │   Expert    │  │  Engineer   │          │
│  │             │  │             │  │             │          │
│  │ model:      │  │ model:      │  │ model:      │          │
│  │ claude      │  │ claude      │  │ claude      │          │
│  │ sonnet 4.6  │  │ sonnet 4.6  │  │ sonnet 4.6  │          │
│  │ tools:      │  │ tools:      │  │ tools:      │          │
│  │ basic-      │  │ basic-      │  │ basic-      │          │
│  │ memory/*    │  │ memory/*    │  │ memory/*    │          │
│  └─────────────┘  └─────────────┘  └─────────────┘          │
└─────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│                Basic Memory MCP 伺服器                       │
│  (uvx basic-memory mcp --project multi-agent-system)         │
│                                                               │
│  提供工具:                                                    │
│  ├─ search_notes("關鍵字") → 語意搜尋知識庫                │
│  ├─ read_note(permalink)   → 讀取完整筆記                   │
│  ├─ write_note(title, content, folder) → 寫入/更新筆記     │
│  ├─ build_context(topic)   → 從多筆記組裝上下文             │
│  └─ recent_activity()      → 查看最近變更                   │
│                                                               │
│  底層儲存: .github/memory-kb/ (Markdown 檔案)               │
│  索引: 語意向量 + [[wiki-link]] 知識圖譜                     │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│                   文件系統層（持久化）                        │
│                                                               │
│  .github/                                                    │
│  ├── agents/              # Agent 定義（VS Code .agent.md）  │
│  │   ├── pm.agent.md      # PM：agents=['*'], 頂層協調者    │
│  │   ├── crawler.agent.md # 爬蟲專家                         │
│  │   ├── database.agent.md # 資料庫專家                      │
│  │   └── frontend.agent.md # 前端工程師                      │
│  │                                                            │
│  ├── copilot-instructions.md  # 全域規則與 SOP（自動載入）    │
│  │                                                            │
│  ├── memory-kb/           # Basic Memory 知識庫（Markdown）  │
│  │   ├── conversations/   # 重要會話紀錄與架構決策            │
│  │   ├── project/         # PM 管理的全局筆記                │
│  │   │   ├── project-overview.md                             │
│  │   │   ├── known-issues.md                                 │
│  │   │   └── memory-system-gaps.md                           │
│  │   ├── crawler/         # 爬蟲經驗                         │
│  │   ├── database/        # 資料庫經驗                       │
│  │   └── frontend/        # 前端經驗                         │
│  │                                                            │
│  ├── hooks/               # 自動化腳本（7 個生命週期事件）   │
│  │   ├── hooks.json       # Hook 配置                        │
│  │   ├── session-init.*   # SessionStart：提醒用 search_notes│
│  │   ├── log-prompt.*     # UserPromptSubmit：審計日誌       │
│  │   ├── post-tool-use.*  # PostToolUse：記錄工具使用        │
│  │   ├── subagent-start.* # SubagentStart：注入記憶提示      │
│  │   ├── subagent-stop.*  # SubagentStop：偵測記憶是否更新   │
│  │   ├── pre-compact.*    # PreCompact：壓縮前注入摘要       │
│  │   └── stop.*           # Stop：提醒更新記憶               │
│  │                                                            │
│  ├── reports/             # 任務報告                          │
│  └── logs/                # 審計日誌                          │
│                                                               │
│  .vscode/                                                    │
│  └── mcp.json             # Basic Memory MCP 伺服器設定      │
└──────────────────────────────────────────────────────────────┘
```

---

## 關鍵的 Frontmatter 欄位

VS Code Copilot 的 `.agent.md` 支持以下關鍵欄位（本專案使用的）：

| 欄位 | 用途 | 本專案用法 |
|------|------|-----------|
| `tools` | Agent 可用的工具 | PM 有 `agent` + `basic-memory/*`；專家有 `basic-memory/*` |
| `agents` | 可呼叫的 subagent 白名單 | PM 設為 `['*']`（全部） |
| `model` | 偏好模型 | PM: claude opus 4.6，專家: claude sonnet 4.6 |
| `disable-model-invocation` | 禁止被其他 agent 呼叫 | PM 設為 `true`（頂層） |

---

## 工作流程

### 完整流程：用戶 → PM → Subagents → 記憶更新

```
用戶打開 VS Code，選擇 Project Manager
  ↓
[SessionStart Hook] 提醒 PM 用 search_notes 查詢 Basic Memory
  ↓
[UserPromptSubmit Hook] 記錄用戶的提示到 prompts-[date].log
  ↓
PM 用 search_notes 查詢記憶，分析需求，提出計劃
  → 「根據記憶，已知 PROXY-001 問題已用 VPN 解決...」
  → 「我計劃調用 Crawler Expert 和 Database Expert...」
  ↓
用戶確認計劃 ✓
  ↓
PM 調用 Subagents
  ├─ [SubagentStart Hook] 注入 memory-kb folder 路徑 + 現有筆記列表 + 記錄時間戳
  ├─ Crawler Expert → search_notes → 開發 → 測試 → 寫報告 → write_note
  ├─ Database Expert → search_notes → 設計 → 實現 → 寫報告 → write_note
  └─ Frontend Engineer → search_notes → 設計 → 實現 → 寫報告 → write_note
  ↓
[SubagentStop Hook] 偵測 memory-kb/{folder}/ 是否有新增/修改 → 未更新則警告
  ↓
PM 收集 .github/reports/ 下的報告
  → 檢查衝突和依賴
  → 整合結果
  ↓
PM 用 write_note 更新 project-overview.md（新任務、新問題、新解法）
  ↓
PM 向用戶報告完成狀態
  ↓
[Stop Hook] 檢查 memory-kb 是否已更新，未更新則提醒
```

### 長對話保護

```
對話接近 context 上限
  ↓
[PreCompact Hook] 讀取 project-overview.md，注入專案摘要 + 知識庫統計
  → 提示 agent 用 search_notes 重新查詢記憶
```

---

## 記憶系統：Basic Memory

### 核心概念

Basic Memory 是一個 MCP 伺服器，將 Markdown 筆記轉換為可語意搜尋的知識圖譜。

```
Agent 呼叫 search_notes("TWSE SSL")
        ↓
  Basic Memory MCP
  ┌─────────────────────────────────────┐
  │  語意向量搜尋                       │
  │  + [[wiki-link]] 知識圖譜遍歷      │
  └─────────────┬───────────────────────┘
                ↓
  回傳最相關的筆記片段（非全量載入）
        ↓
  Agent 得到精準 context（~200 tokens vs 舊版 2000+）

Agent 呼叫 write_note("TWSE-SSL-fallback", content, folder="crawler")
        ↓
  Basic Memory MCP
  ┌─────────────────────────────────────┐
  │  寫入 .github/memory-kb/crawler/   │
  │  自動提取 Observations (key::value) │
  │  自動建立 [[wiki-link]] Relations  │
  │  更新語意索引                       │
  └─────────────────────────────────────┘
```

### 記憶層級

```
Level 0: 全局規範
  └─ .github/copilot-instructions.md（如果存在）

Level 1: 專案級記憶（Basic Memory project: multi-agent-system）
  └─ .github/memory-kb/
     ├── project/    ← PM 管理：專案狀態、已知問題、架構決策
     ├── crawler/    ← Crawler Expert：爬蟲經驗、反偵測技巧、API 特性
     ├── database/   ← Database Expert：模型設計、遷移經驗、效能調校
     └── frontend/   ← Frontend Engineer：設計系統、組件庫、圖表經驗

Level 2: 任務級 context（PM 動態組裝）
  └─ PM 用 search_notes 從知識庫精準檢索，只傳遞相關記憶給 subagent
```

### 記憶讀寫時機

| 時機 | 操作 | 機制 |
|------|------|------|
| 會話開始 | 提醒查詢 Basic Memory | SessionStart Hook 注入 search_notes 提示 |
| Subagent 啟動 | 注入 folder 路徑 + 筆記列表 | SubagentStart Hook + 記錄啟動時間戳 |
| 任務執行中 | Agent 主動搜尋 | Agent 呼叫 search_notes / read_note |
| 任務完成 | Agent 寫入經驗 | Agent 呼叫 write_note |
| Subagent 結束 | 偵測記憶是否更新 | SubagentStop Hook 比對時間戳 vs 檔案修改時間 |
| Context 壓縮前 | 注入專案摘要 | PreCompact Hook 讀取 project-overview.md |
| 會話結束 | 檢查記憶是否更新 | Stop Hook 檢查 project-overview.md 修改時間 |

### 記憶隔離

- `project/` — PM 管理，全局狀態和已知問題
- `crawler/` / `database/` / `frontend/` — 各 agent 負責自己的資料夾
- 語意搜尋搜全專案，靠 Observations 中的 `app :: mta_demo2` 等標籤區分子應用

---

## Hooks 系統

### 7 個生命週期事件

| Hook | 觸發時機 | 作用 |
|------|---------|------|
| **SessionStart** | 新會話開始 | 提醒用 search_notes 查詢記憶 |
| **UserPromptSubmit** | 用戶送出提示 | 記錄到審計日誌 |
| **PreCompact** | Context 即將壓縮 | 讀取 project-overview.md 注入摘要 |
| **SubagentStart** | Subagent 被呼叫 | 注入 memory-kb folder + 筆記列表 + 時間戳 |
| **SubagentStop** | Subagent 完成 | 偵測記憶是否更新，未更新則警告 |
| **PostToolUse** | 工具執行完成 | 記錄工具使用（審計） |
| **Stop** | 會話結束 | 檢查 memory-kb 是否已更新 |

### Hook 資料流

```
Hook 觸發 → 腳本接收 JSON (stdin) → 讀取 memory-kb → 返回 JSON (stdout)
                                                          ↓
                                               additionalContext → 注入到 agent context
                                               systemMessage → 顯示給用戶
                                               continue: false → 阻止操作
```

### SubagentStart → SubagentStop 記憶偵測機制

```
SubagentStart Hook
  → 記錄時間戳到 logs/subagent-start-{id}.timestamp
  → 注入 memory-kb folder 路徑 + 現有筆記列表
       ↓
    Subagent 執行任務
    用 write_note 寫入 memory-kb/{folder}/
       ↓
SubagentStop Hook
  → 讀取時間戳
  → 掃描 memory-kb/{folder}/ 是否有比時間戳新的檔案
  → ✅ 有更新 → 顯示已更新的筆記名
  → ❌ 沒更新 → 注入「未更新記憶 = 任務未完成」警告
```

---

## 設計原則

1. **PM 不寫代碼** — PM 只做協調、分工、記憶管理，業務代碼交給專家 agent
2. **語意搜尋取代全量載入** — 用 search_notes 精準檢索，不把全部記憶塞進 context
3. **Hook 偵測 + 指令強制** — SubagentStop 自動偵測記憶更新，agent 指令要求「未更新 = 未完成」
4. **並行執行** — 無依賴的 subagent 任務並行調用
5. **問題不重複** — known-issues.md 是核心資產，每次任務前必須 search_notes
6. **容錯** — 所有 Hook 失敗時 `continue: true`，不阻止會話
7. **人機共讀** — 記憶以 Markdown 儲存，人類可直接檢視和修正

---

## 模型名稱注意事項

`model` 欄位的值取決於你的 Copilot 方案支持的模型。請在 VS Code 的模型選擇器中查看可用模型名稱，並相應修改各 `.agent.md` 的 `model` 欄位。如果指定的模型不可用，VS Code 會按陣列順序 fallback 到下一個。
