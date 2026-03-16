# 系統架構說明

## 🏗️ 架構設計

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
│  │                   Project Manager                    │   │
│  │                   （協調和編排）                     │   │
│  │                                                      │   │
│  │  • 查閱項目記憶                                       │   │
│  │  • 決定調用哪些 Agents                              │   │
│  │  • 整合結果和更新記憶                                │   │
│  └──────────────────────────────────────────────────────┘   │
│              ↓                ↓                ↓               │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │
│  │  Crawler    │  │  Database   │  │  Frontend   │          │
│  │   Expert    │  │   Expert    │  │  Engineer   │          │
│  │             │  │             │  │             │          │
│  │ 加載記憶    │  │ 加載記憶    │  │ 加載記憶    │          │
│  │ 執行任務    │  │ 執行任務    │  │ 執行任務    │          │
│  │ 保存進度    │  │ 保存進度    │  │ 保存進度    │          │
│  └─────────────┘  └─────────────┘  └─────────────┘          │
└─────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│                   文件系統層（持久化）                        │
│                                                               │
│  .github/                                                    │
│  ├── agents/              # Agent 定義（VS Code 標準）       │
│  │   ├── pm.agent.md      # PM 協調員 (5 個工具)             │
│  │   ├── crawler.agent.md # 爬蟲 (4 個工具)                  │
│  │   ├── database.agent.md # 數據庫 (3 個工具)               │
│  │   └── frontend.agent.md # 前端 (3 個工具)                 │
│  │                                                            │
│  ├── memory/              # 永久記憶                         │
│  │   ├── project-state.json       # 全局狀態 + 權限歷史      │
│  │   ├── crawler-memory.json      # 爬蟲經驗 + 已知問題      │
│  │   ├── database-memory.json     # 數據庫設計 + 遷移經驗    │
│  │   ├── frontend-memory.json     # 設計系統 + 組件庫        │
│  │   └── session-[ID].json        # 會話日誌                 │
│  │                                                            │
│  ├── tools/               # 工具和 MCP 管理 (新增)           │
│  │   ├── TOOLS_MANIFEST.md        # 工具資源庫文檔           │
│  │   ├── mcp-registry.json        # MCP 和工具註冊表        │
│  │   ├── PERMISSION_WORKFLOW.md   # 權限流程                 │
│  │   └── PM_QUICK_REFERENCE.md    # PM 快速查詢卡           │
│  │                                                            │
│  ├── hooks/               # 自動化腳本                        │
│  │   ├── hooks.json                    # 配置                │
│  │   ├── session-init.ps1              # 會話初始化          │
│  │   ├── subagent-start.ps1            # Subagent 啟動       │
│  │   ├── subagent-stop.ps1             # Subagent 完成       │
│  │   ├── post-tool-use.ps1             # 工具後處理          │
│  │   └── log-prompt.ps1                # 提示記錄            │
│  │                                                            │
│  ├── reports/             # 任務報告                          │
│  │   └── [agent]-report-[timestamp].md                       │
│  │                                                            │
│  └── logs/                # 審計日誌                          │
│      ├── tool-usage-YYYY-MM-DD.log                           │
│      └── prompts-YYYY-MM-DD.log                              │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

---

## 🔄 工作流程

### 工作流 1: 用戶初始化

```
1. 用戶打開 VS Code
   ↓
2. VS Code 自動掃描 .github/agents/ 目錄
   ↓
3. 加載所有 .agent.md 文件作為 Agents
   ↓
4. 將 Agents 顯示在下拉菜單中
   ↓
5. 從 .github/hooks/hooks.json 加載 Hooks 配置
```

### 工作流 2: 用戶與 PM 對話

```
1. 用戶選擇 Project Manager
   ↓
2. 用戶提交需求 (UserPromptSubmit Hook)
   ├─ 記錄用戶提示到 prompts-[date].log
   └─ (返回 continue: true，允許對話繼續)
   ↓
3. SessionStart Hook 觸發
   ├─ 讀取 project-state.json
   ├─ 讀取已知問題和解決方案
   └─ 注入上下文到 PM 的對話中
   ↓
4. PM 基於注入的上下文做決策
   ├─ 參考已知問題
   ├─ 提出執行計劃
   └─ 建議調用的 Agents
   ↓
5. 用戶選擇 Subagent（例如：Crawler Expert）
```

### 工作流 3: Subagent 執行

```
1. 用戶選擇 Subagent (例如 Crawler Expert)
   ↓
2. SubagentStart Hook 觸發
   ├─ 確定 Agent 類型（Crawler Expert）
   ├─ 查找對應的記憶文件（crawler-memory.json）
   ├─ 讀取已解決的問題和最佳實踐
   └─ 注入到 Subagent 的對話上下文中
   ↓
3. Subagent 執行任務
   ├─ 檢查記憶中的已知問題（例如：Proxy 問題）
   ├─ 應用過去的解決方案
   ├─ 執行新的工作
   └─ 記錄任何新發現
   ↓
4. PostToolUse Hook（多次觸發）
   ├─ 記錄每次工具調用
   ├─ 記錄工具輸入和響應
   └─ 保存到 tool-usage-[date].log
   ↓
5. Subagent 完成
   ├─ 生成報告文件
   └─ 返回給 PM
   ↓
6. SubagentStop Hook 觸發
   ├─ 記錄完成事件
   ├─ 保存到 session-[ID].json
   ├─ 可選：更新 Agent 的記憶文件
   └─ 返回 continue: true 或生成提示繼續
   ↓
7. 返回 PM
```

### 工作流 4: PM 整合結果

```
1. PM 接收所有 Subagents 的報告
   ↓
2. PM 分析依賴關係和衝突
   ↓
3. PM 整合結果
   ├─ 合併所有輸出
   ├─ 識別下一步行動
   └─ 提出最終計劃
   ↓
4. PM 更新項目記憶
   ├─ 更新 project-state.json
   ├─ 添加新的已知問題（如有）
   └─ 更新活躍任務列表
   ↓
5. PM 向用戶報告
   ├─ 展示完成狀態
   ├─ 列出下一步行動
   └─ 提供記憶更新摘要
```

---

## 🧠 記憶系統詳解

### 記憶層級

```
Level 1: 項目全局記憶 (project-state.json)
├─ 項目名稱和階段
├─ 活躍任務列表
├─ 已知全局問題和解決方案
└─ 系統整體狀態

Level 2: Agent 專業記憶
├─ Crawler Expert
│  ├─ 已解決的爬蟲問題
│  ├─ Proxy 和反爬蟲技巧
│  ├─ 最佳實踐
│  └─ 爬蟲過的網站列表
├─ Database Expert
│  ├─ 設計過的 ORM 模型
│  ├─ 遷移經驗
│  ├─ 性能優化技巧
│  └─ 備份策略
└─ Frontend Engineer
   ├─ 設計系統
   ├─ 組件庫
   ├─ 可訪問性指南
   └─ 色彩方案

Level 3: 會話日誌 (session-[ID].json)
├─ 會話開始時間
├─ 完成的 Agents 列表
├─ 時間戳和狀態
└─ 報告文件位置
```

### 記憶更新點

1. **SessionStart** - 讀取並注入項目記憶
2. **SubagentStart** - 讀取並注入 Agent 記憶
3. **PostToolUse** - 記錄工具使用
4. **SubagentStop** - 保存會話事件
5. **用戶手動編輯** - 直接編輯 JSON 文件

---

## ⚙️ Hooks 系統

### Hook 事件和觸發時機

| Hook 事件 | 觸發時機 | 用途 |
|---------|---------|------|
| **SessionStart** | 會話開始 | 初始化記憶、加載上下文 |
| **UserPromptSubmit** | 用戶提交提示 | 記錄用戶請求、審計 |
| **SubagentStart** | Subagent 啟動 | 加載 Agent 記憶、初始化 |
| **SubagentStop** | Subagent 完成 | 保存進度、生成報告 |
| **PostToolUse** | 工具執行後 | 記錄工具使用、審計 |
| **PreToolUse** | 工具執行前 | 驗證、安全檢查（未使用） |

### Hook 執行流程

```
Hook 觸發
    ↓
Hook 腳本接收 JSON 輸入（包含事件特定信息）
    ↓
Hook 腳本讀取相關文件（記憶、配置等）
    ↓
Hook 腳本執行業務邏輯
    ↓
Hook 腳本返回 JSON 輸出
    ├─ continue: true/false
    ├─ systemMessage: 警告或信息
    └─ hookSpecificOutput:
       └─ additionalContext: 注入到 Agent 的上下文
    ↓
VS Code 處理返回值
    ├─ 如果 continue: false，停止會話
    ├─ 如果有 systemMessage，顯示給用戶
    └─ 如果有 additionalContext，注入到 Agent
```

---

## 🔒 分工和安全

### Agent 責任分離

```
Project Manager
└─ 職責：協調、規劃、記憶整合
   └─ 限制：read-only 工具
      └─ 不直接修改代碼，只查閱和建議

Crawler Expert
└─ 職責：爬蟲開發
   └─ 限制：只關注爬蟲領域
      └─ 記憶：已知的爬蟲問題和解決方案

Database Expert
└─ 職責：數據庫設計
   └─ 限制：只關注數據模型
      └─ 記憶：設計模式和遷移經驗

Frontend Engineer
└─ 職責：UI/UX 實現
   └─ 限制：只關注前端領域
      └─ 記憶：設計系統和組件庫
```

### 記憶隔離

```
project-state.json
├─ 全局可讀（所有 Agents 可訪問）
└─ 只有 PM 可更新

crawler-memory.json
├─ Crawler Expert 主要使用
├─ 其他 Agents 可查閱
└─ Crawler Expert 可更新

database-memory.json
├─ Database Expert 主要使用
├─ 其他 Agents 可查閱
└─ Database Expert 可更新

frontend-memory.json
├─ Frontend Engineer 主要使用
├─ 其他 Agents 可查閱
└─ Frontend Engineer 可更新
```

---

## 📊 數據流

```
用戶輸入
    ↓
[UserPromptSubmit Hook] → 記錄到 prompts-[date].log
    ↓
Agent 接收提示
    ↓
[SessionStart Hook (首次)] → 注入項目記憶
    ↓
Agent 生成回應
    ↓
如果調用其他 Agents：
    ├─ [SubagentStart Hook] → 注入 Agent 記憶
    ├─ Subagent 執行任務
    ├─ [PostToolUse Hook (多次)] → 記錄工具使用
    └─ [SubagentStop Hook] → 保存進度
    ↓
Agent 生成最終回應
    ↓
[用戶手動或自動] 更新記憶文件
    ↓
下次會話
    ├─ [SessionStart Hook] → 加載更新後的記憶
    └─ 循環開始
```

---

## 🛡️ 權限和工具管理系統 (新增)

### 概述

新的權限管理系統讓 PM 能夠：

1. **自動檢查** - 驗證 Subagents 是否具備所需工具
2. **智能推薦** - 查詢 MCP 資源庫推薦最佳方案
3. **安全控制** - 確保開放的工具符合安全標準
4. **節省 Token** - 優先推薦 MCP，避免重複造輪子

### 核心流程

```
Agent 需要新工具
  ↓
向 PM 報告需求
  ↓
PM 查詢 MCP 資源庫 (.github/tools/)
  ├─ TOOLS_MANIFEST.md (人類可讀)
  └─ mcp-registry.json (結構化)
  ↓
PM 評估
  ├─ 功能是否完全?
  ├─ 安全性如何?
  └─ Token 消耗是否合理?
  ↓
PM 推薦方案 (優先級)
  1. 使用現有 MCP (最省 Token)
  2. 官方推薦 MCP
  3. 社區 MCP
  4. 直接開放工具
  ↓
PM 向用戶報告
  └─ 請求批准或建議替代方案
```

### 工具配置優化

| Agent | 初始 | 最終 | 節省 | 工具集 |
|-------|------|------|------|--------|
| **PM** | 9 | 5 | 44% | execute, read, edit, search, agent |
| **Crawler** | 11 | 4 | 64% | read, edit, execute, search |
| **Database** | 11 | 3 | 73% | read, edit, search |
| **Frontend** | 8 | 3 | 63% | read, edit, search |

### MCP 資源庫

新系統集成了：
- **官方 MCPs**: Brave Search, GitHub, Postgres, Docker, Git
- **社區 MCPs**: BeautifulSoup, SQLAlchemy, Chart.js, pytest, django
- **自定義 MCPs**: Dcard Crawler (範例)

---

## 🎯 設計原則

### 1. 分工明確
- 每個 Agent 有明確的職責和工具集
- 記憶按領域分離
- 避免跨領域污染

### 2. 自動化
- Hooks 自動在關鍵點執行
- 記憶自動加載和注入
- PM 自動檢查權限
- 日誌自動記錄

### 3. 可追溯
- 所有操作都有審計日誌
- 會話事件被記錄
- 工具開放決策被記錄
- 記憶版本可查詢

### 4. 可擴展
- 易於添加新 Agents
- 易於添加新 Hooks
- 易於添加新 MCP
- 易於擴展記憶字段
- 易於擴展權限管理

### 5. 容錯和安全
- Hooks 失敗不阻止會話（exit 1）
- 缺少記憶文件可優雅降級
- JSON 解析錯誤被捕獲
- 工具開放前有多層檢查
- 權限限制防止誤操作

### 6. Token 效率
- 優先推薦 MCP 而非直接工具
- 避免給 Agents 不必要的工具
- MCP 通常比直接工具更輕量
- 減少 Agents 間的通信開銷

---

## 🔧 配置檢查清單

- [ ] `.github/agents/` 存在並包含 4 個 `.agent.md` 文件
- [ ] `.github/memory/` 存在並包含 JSON 記憶文件
- [ ] `.github/hooks/hooks.json` 存在並配置正確
- [ ] PowerShell 腳本都在 `.github/hooks/` 目錄中
- [ ] `.github/reports/` 和 `.github/logs/` 目錄存在
- [ ] JSON 文件格式有效（使用 jq 驗證）
- [ ] 在 VS Code 中打開 workspace 並檢查 Agents 下拉菜單

---

**架構完成！** 系統已準備好進行多 Agent 協作。
