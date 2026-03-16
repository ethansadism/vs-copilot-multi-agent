# 系統架構說明

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
│  │          model: claude-sonnet-4 / gpt-4o             │   │
│  │          agents: ['*']  ← 可呼叫所有 subagent       │   │
│  │                                                      │   │
│  │  • 讀取記憶 → 分析需求 → 提計劃 → 等確認 → 分工   │   │
│  └──────────────────────────────────────────────────────┘   │
│         ↓ (subagent)       ↓ (subagent)      ↓ (subagent)   │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │
│  │  Crawler    │  │  Database   │  │  Frontend   │          │
│  │   Expert    │  │   Expert    │  │  Engineer   │          │
│  │             │  │             │  │             │          │
│  │ model:      │  │ model:      │  │ model:      │          │
│  │ gpt-4o-mini │  │ gpt-4o-mini │  │ gpt-4o-mini │          │
│  │ (fallback   │  │ (fallback   │  │ (fallback   │          │
│  │  gpt-4o)    │  │  gpt-4o)    │  │  gpt-4o)    │          │
│  └─────────────┘  └─────────────┘  └─────────────┘          │
└─────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│                   文件系統層（持久化）                        │
│                                                               │
│  .github/                                                    │
│  ├── agents/              # Agent 定義（VS Code 標準）       │
│  │   ├── pm.agent.md      # PM：agents=['*'], model 高階    │
│  │   ├── crawler.agent.md # 爬蟲：model 低階優先            │
│  │   ├── database.agent.md # 資料庫：model 低階優先         │
│  │   └── frontend.agent.md # 前端：model 低階優先           │
│  │                                                            │
│  ├── memory/              # 永久記憶                         │
│  │   ├── project-state.json       # 全局狀態 + 已知問題      │
│  │   ├── crawler-memory.json      # 爬蟲經驗 + 已知問題      │
│  │   ├── database-memory.json     # 資料庫設計 + 遷移經驗    │
│  │   └── frontend-memory.json     # 設計系統 + 組件庫        │
│  │                                                            │
│  ├── tools/               # 工具和 MCP 管理                  │
│  │   ├── TOOLS_MANIFEST.md        # 工具資源庫文檔           │
│  │   ├── mcp-registry.json        # MCP 和工具註冊表        │
│  │   ├── PERMISSION_WORKFLOW.md   # 權限流程                 │
│  │   └── PM_QUICK_REFERENCE.md    # PM 快速查詢卡           │
│  │                                                            │
│  ├── hooks/               # 自動化腳本（7 個生命週期事件）   │
│  │   ├── hooks.json               # Hook 配置               │
│  │   ├── session-init.sh          # SessionStart：注入記憶   │
│  │   ├── log-prompt.sh            # UserPromptSubmit：記錄   │
│  │   ├── post-tool-use.sh         # PostToolUse：審計工具    │
│  │   ├── subagent-start.sh        # SubagentStart：注入記憶  │
│  │   ├── subagent-stop.sh         # SubagentStop：保存進度   │
│  │   ├── pre-compact.sh           # PreCompact：保護記憶     │
│  │   └── stop.sh                  # Stop：提醒更新記憶       │
│  │                                                            │
│  ├── reports/             # 任務報告                          │
│  └── logs/                # 審計日誌                          │
└──────────────────────────────────────────────────────────────┘
```

---

## 關鍵的 Frontmatter 欄位

VS Code Copilot 的 `.agent.md` 支持以下關鍵欄位（本專案使用的）：

| 欄位 | 用途 | 本專案用法 |
|------|------|-----------|
| `tools` | Agent 可用的工具 | PM 有 `agent` 工具可呼叫 subagent |
| `agents` | 可呼叫的 subagent 白名單 | PM 設為 `['*']`（全部） |
| `model` | 偏好模型，陣列 = 依序 fallback | PM 用高階，專家用低階省錢 |
| `disable-model-invocation` | 禁止被其他 agent 呼叫 | PM 設為 `true`（頂層） |

---

## 工作流程

### 完整流程：用戶 → PM → Subagents → 記憶更新

```
用戶打開 VS Code，選擇 Project Manager
  ↓
[SessionStart Hook] 自動注入 project-state.json 到 PM context
  ↓
[UserPromptSubmit Hook] 記錄用戶的提示到 prompts-[date].log
  ↓
PM 讀取記憶，分析需求，提出計劃
  → 「根據記憶，已知 PROXY-001 問題已用 VPN 解決...」
  → 「我計劃調用 Crawler Expert 和 Database Expert...」
  ↓
用戶確認計劃 ✓
  ↓
PM 並行調用 Subagents
  ├─ [SubagentStart Hook] 注入各 agent 的專屬記憶
  ├─ Crawler Expert 執行 → 查記憶 → 開發 → 測試 → 寫報告 → 更新記憶
  ├─ Database Expert 執行 → 查記憶 → 設計 → 實現 → 寫報告 → 更新記憶
  └─ Frontend Engineer 執行 → 查記憶 → 設計 → 實現 → 寫報告 → 更新記憶
  ↓
[SubagentStop Hook] 記錄完成事件到 session log
  ↓
PM 收集 .github/reports/ 下的報告
  → 檢查衝突和依賴
  → 整合結果
  ↓
PM 更新 project-state.json（新任務、新問題、新解法）
  ↓
PM 向用戶報告完成狀態
  ↓
[Stop Hook] 檢查 project-state.json 是否已更新，未更新則提醒
```

### 長對話保護

```
對話接近 context 上限
  ↓
[PreCompact Hook] 自動重新注入關鍵資訊
  → 活躍任務列表
  → 已知問題和解法（避免壓縮後遺忘）
  → 提示 agent 如需完整記憶可重讀檔案
```

---

## 記憶系統

### 記憶層級

```
Level 1: 全局記憶 (project-state.json)
├─ 專案名稱和階段
├─ 已完成的任務
├─ 已知問題和解決方案 ← 最有價值的部分
└─ 系統狀態

Level 2: Agent 專屬記憶
├─ crawler-memory.json  → 爬蟲問題、Proxy 技巧、反爬蟲經驗
├─ database-memory.json → ORM 模型、遷移經驗、性能優化
└─ frontend-memory.json → 設計系統、組件庫、色彩方案
```

### 記憶讀寫時機

| 時機 | 操作 | 機制 |
|------|------|------|
| 會話開始 | 讀取 project-state.json | SessionStart Hook 自動注入 |
| Subagent 啟動 | 讀取對應的 agent memory | SubagentStart Hook 自動注入 |
| 工具使用後 | 記錄工具調用 | PostToolUse Hook 寫入 log |
| Subagent 結束 | 記錄完成事件 | SubagentStop Hook 寫入 session log |
| Context 壓縮前 | 重新注入關鍵資訊 | PreCompact Hook |
| 會話結束 | 檢查記憶是否已更新 | Stop Hook |

### 記憶隔離

- `project-state.json` — 所有 agent 可讀，PM 負責更新
- `*-memory.json` — 對應 agent 負責更新，其他 agent 可查閱不可修改

---

## Hooks 系統

### 7 個生命週期事件

| Hook | 觸發時機 | 作用 |
|------|---------|------|
| **SessionStart** | 新會話開始 | 注入全局記憶到 context |
| **UserPromptSubmit** | 用戶送出提示 | 記錄到審計日誌 |
| **PreCompact** | Context 即將壓縮 | 重新注入關鍵資訊，防遺忘 |
| **SubagentStart** | Subagent 被呼叫 | 注入該 agent 的專屬記憶 |
| **SubagentStop** | Subagent 完成 | 記錄完成事件 |
| **PostToolUse** | 工具執行完成 | 記錄工具使用（審計） |
| **Stop** | 會話結束 | 檢查記憶是否已更新 |

### Hook 資料流

```
Hook 觸發 → 腳本接收 JSON (stdin) → 讀取記憶檔 → 返回 JSON (stdout)
                                                          ↓
                                               additionalContext → 注入到 agent context
                                               systemMessage → 顯示給用戶
                                               continue: false → 阻止操作
```

---

## 設計原則

1. **PM 不寫代碼** — PM 只做協調、分工、記憶管理，業務代碼交給專家 agent
2. **記憶自動注入** — Hook 機械式地在關鍵時刻注入記憶，不依賴 LLM 自律
3. **低階模型優先** — 專家 agent 優先使用便宜模型，降低成本
4. **並行執行** — 無依賴的 subagent 任務並行調用
5. **問題不重複** — known_issues 是核心資產，每次任務前必須檢查
6. **容錯** — 所有 Hook 失敗時 `continue: true`，不阻止會話

---

## 模型名稱注意事項

`model` 欄位的值取決於你的 Copilot 方案支持的模型。請在 VS Code 的模型選擇器中查看可用模型名稱，並相應修改各 `.agent.md` 的 `model` 欄位。如果指定的模型不可用，VS Code 會按陣列順序 fallback 到下一個。
