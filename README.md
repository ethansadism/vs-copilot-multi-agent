# Multi-Agent Collaboration System

本項目展示了基於 VS Code Copilot 的企業級多 Agent 協作系統，完全符合 GitHub Copilot 的官方標準。

## 🎯 系統架構

### 四個 Agent 角色

- **Project Manager** - 協調員，管理項目進度、分配任務、整合結果、檢查權限
- **Crawler Expert** - 爬蟲專家，開發網站爬蟲，避免重複錯誤，適應反爬蟲機制
- **Database Expert** - 數據庫專家，設計數據模型，優化查詢，管理遷移
- **Frontend Engineer** - 前端工程師，實現 UI/UX、設計圖表、優化視覺效果

### 核心特性

✅ **永久記憶系統** - 每個 Agent 有獨立的記憶庫（`.github/memory/`），避免重複錯誤  
✅ **分工明確** - 每個 Agent 專注於自己的領域，記憶乾淨隔離  
✅ **智能權限管理** - PM 自動檢查權限，推薦 MCP，節省 Token  
✅ **自動記憶加載** - SessionStart Hook 自動加載項目記憶  
✅ **MCP 資源庫** - 內置官方和社區 MCP 推薦，避免重複造輪子  
✅ **工作流自動化** - Hooks 在關鍵生命週期自動執行  
✅ **會話審計** - 所有對話、工具使用、權限決策都被記錄

## 📁 項目結構

```
multi_agent_system/
├── README.md                         # 本文件
├── QUICKSTART.md                    # 30 秒快速開始
├── DEMO_GUIDE.md                    # 完整演示指南
├── ARCHITECTURE.md                  # 系統架構詳解
├── CHECKLIST.md                     # 驗證和故障排除
├── OVERVIEW.md                      # 項目總覽
├── IMPLEMENTATION_COMPLETE.md       # 完成報告
│
└── .github/
    ├── agents/                      # Agent 定義（VS Code 標準）
    │   ├── pm.agent.md              # Project Manager (5 個工具)
    │   ├── crawler.agent.md         # Crawler Expert (4 個工具)
    │   ├── database.agent.md        # Database Expert (3 個工具)
    │   └── frontend.agent.md        # Frontend Engineer (3 個工具)
    │
    ├── memory/                      # 永久記憶系統
    │   ├── project-state.json       # 項目狀態 + 權限歷史
    │   ├── crawler-memory.json      # 爬蟲經驗 + 已知問題
    │   ├── database-memory.json     # 數據庫設計 + 遷移經驗
    │   ├── frontend-memory.json     # 設計系統 + 組件庫
    │   └── session-[ID].json        # 會話日誌
    │
    ├── tools/                       # 工具和 MCP 管理 (新增)
    │   ├── TOOLS_MANIFEST.md        # 工具資源庫文檔
    │   ├── mcp-registry.json        # MCP 和工具註冊表
    │   ├── PERMISSION_WORKFLOW.md   # 權限請求流程
    │   └── PM_QUICK_REFERENCE.md    # PM 快速查詢卡
    │
    ├── hooks/                       # 自動化工作流
    │   ├── hooks.json               # 配置文件
    │   ├── session-init.ps1         # SessionStart - 初始化記憶
    │   ├── subagent-start.ps1       # SubagentStart - 加載 Agent 記憶
    │   ├── subagent-stop.ps1        # SubagentStop - 保存進度
    │   ├── post-tool-use.ps1        # PostToolUse - 記錄工具使用
    │   └── log-prompt.ps1           # UserPromptSubmit - 記錄用戶請求
    │
    ├── reports/                     # 任務報告
    │   └── [agent-type]-report-[timestamp].md
    │
    └── logs/                        # 審計日誌
        ├── tool-usage-YYYY-MM-DD.log
        └── prompts-YYYY-MM-DD.log
```

## 🚀 快速開始

### 1. 打開項目

在 VS Code 中打開此 workspace：

```bash
git clone https://github.com/[你的用戶名]/multi_agent_system.git
code multi_agent_system
```

系統會自動：
- ✅ 檢測 `.github/agents/` 中的所有 Agent
- ✅ 從 `.github/hooks/hooks.json` 加載 Hooks 配置
- ✅ 準備好記憶系統

### 2. 與 PM 對話

1. 打開 Copilot Chat（`Ctrl+L` 或點擊左邊欄 Copilot 圖標）
2. 在 Agents 下拉菜單中選擇 **"Project Manager"**
3. 提交你的需求

**範例需求**：
```
我需要爬取 Dcard 股票版的數據，
設計一個儲存數據的模型，
然後創建一個 Dashboard 顯示前 10 支熱門股票。
```

### 3. 觀察 PM 的工作流程

```
用戶需求
  ↓
PM 查閱記憶 (SessionStart Hook)
  ├─ ✓ 檢查已知問題 (Proxy 被封)
  ├─ ✓ 檢查權限充分性
  └─ ✓ 查詢 MCP 資源庫
  ↓
PM 分析並制定計劃
  ├─ 調用 Crawler Expert
  ├─ 調用 Database Expert
  └─ 調用 Frontend Engineer
  ↓
PM 整合結果並更新記憶
  └─ ✓ 項目記憶已保存供未來使用
```

## 🆕 新增：智能權限和 MCP 管理

### PM 的新能力

PM 現在可以：

1. **自動檢查權限** - 驗證 Subagent 是否有所需工具
   ```
   PM: "Crawler Expert 需要 [工具] 來完成 [任務]"
   PM: "檢查中... ✓ 該 Agent 已具備所需工具"
   ```

2. **查詢 MCP 資源庫** - 發現和推薦最佳工具
   ```
   PM: "我需要為 Database Expert 找 ORM 工具"
   PM: "推薦 SQLAlchemy MCP - 功能完整，Token 消耗中等"
   ```

3. **評估 Token 消耗** - 優先推薦 MCP 而非直接工具
   ```
   選項 A: 直接開放 ms-python.python (Token ++++)
   選項 B: 使用 pip-mcp (Token ++)
   推薦: 選項 B
   ```

4. **記錄所有決策** - 維護權限和工具使用審計日誌
   ```
   .github/memory/project-state.json
   ├─ agent_permissions[]  # 所有開放的工具
   └─ mcp_usage[]         # 所有集成的 MCPs
   ```

### 文檔導航

- **[TOOLS_MANIFEST.md](.github/tools/TOOLS_MANIFEST.md)** - 工具和 MCP 完整資源庫
- **[mcp-registry.json](.github/tools/mcp-registry.json)** - 結構化 MCP 數據
- **[PERMISSION_WORKFLOW.md](.github/tools/PERMISSION_WORKFLOW.md)** - 詳細工作流程
- **[PM_QUICK_REFERENCE.md](.github/tools/PM_QUICK_REFERENCE.md)** - PM 快速查詢卡

## 📚 完整文檔

| 文檔 | 用途 | 時間 |
|------|------|------|
| **QUICKSTART.md** | 30秒上手 | 5 分鐘 |
| **README.md** | 完整說明（本文件） | 10 分鐘 |
| **ARCHITECTURE.md** | 系統設計和原理 | 30 分鐘 |
| **DEMO_GUIDE.md** | 完整演示流程 | 15 分鐘 |
| **CHECKLIST.md** | 驗證和故障排除 | 需要時 |
| **TOOLS_MANIFEST.md** | 工具 MCP 資源庫 | 參考用 |
PM 推薦調用其他 Agent (通過 Handoffs 或直接建議)
    ↓
選擇 Subagent（Crawler/Database/Frontend）
    ↓
Subagent 加載其記憶 (SubagentStart Hook)
    ↓
Subagent 檢查已解決的問題，避免重複錯誤
    ↓
Subagent 執行任務
    ↓
Subagent 完成任務，保存記憶 (SubagentStop Hook)
    ↓
PM 讀取報告，整合結果，更新項目記憶
    ↓
向用戶報告完成狀態
```

## 📚 記憶系統說明

### project-state.json
存儲項目級別的信息：
- 當前進度和階段
- 已知問題和解決方案
- 活躍任務列表
- 系統狀態

### Agent 特定記憶
- **crawler-memory.json** - 已解決的爬蟲問題、代理和反爬蟲技巧
- **database-memory.json** - 數據庫設計模式、遷移經驗、性能最佳實踐
- **frontend-memory.json** - 設計系統、組件庫、可訪問性指南

### 記憶更新機制

1. **SessionStart** - 加載項目記憶到對話上下文
2. **SubagentStart** - 加載 Agent 特定記憶
3. **SubagentStop** - 保存完成事件和會話日誌
4. **PostToolUse** - 記錄工具使用和進度
5. **UserPromptSubmit** - 記錄用戶請求

## 💡 示例場景

### 場景：開發新功能需要三個 Agent 協作

**用戶**: "我需要爬取 5 個新網站，準備新的 Dashboard，並優化數據模型"

**PM 的決策**:
1. 查閱記憶 → 發現上月 Proxy 問題已解決（使用 VPN）
2. 規劃任務：
   - 調用爬蟲專家 → 告訴他使用 VPN 解決方案
   - 調用數據庫專家 → 設計新模型
   - 調用前端工程師 → 設計新 Dashboard

**爬蟲專家**:
- 加載記憶 → 看到 Proxy 問題的解決方案
- 在開發中遇到 IP 被封 → 立即應用 VPN 解決方案
- 完成任務，保存任何新發現

**最終**:
- PM 收集所有報告
- 更新項目記憶
- 向用戶報告完成狀態

## 🔧 配置和自定義

### 修改 Agent 指令

編輯 `.github/agents/[agent-name].agent.md` 的 Body 部分。  
Agent 將使用更新後的指令進行對話。

### 添加新的 Hooks

1. 編輯 `.github/hooks/hooks.json` 添加新事件
2. 創建對應的 PowerShell 腳本（Windows）或 Bash 腳本（Linux/macOS）
3. 重啟 VS Code 以加載新的 Hook 配置

### 更新記憶

直接編輯 `.github/memory/` 中的 JSON 文件，或讓 Hooks 自動更新。  
下次會話開始時，更新後的記憶將自動加載。

## 📊 監控和調試

### 查看加載的 Agents

1. 打開 Copilot Chat
2. 在 Agents 下拉菜單中查看所有可用的 Agent
3. 將鼠標懸停在 Agent 名稱上查看其源位置

### 查看 Hooks 診斷

1. 打開 Output 面板（View → Output）
2. 選擇 **"GitHub Copilot Chat Hooks"** 頻道
3. 查看 Hook 執行日誌和錯誤

### 查看審計日誌

- `.github/logs/tool-usage-YYYY-MM-DD.log` - 工具使用記錄
- `.github/logs/prompts-YYYY-MM-DD.log` - 用戶提示記錄
- `.github/memory/session-[ID].json` - 會話完成事件

## 🎓 最佳實踐

1. **記憶維護** - 定期檢查和更新 Agent 記憶中的已知問題
2. **Hook 日誌** - 檢查 Hooks 執行日誌以排除故障
3. **分工明確** - 確保每個 Agent 的指令集中於其專業領域
4. **問題文檔** - 新遇到的問題都應記錄在相應的 Agent 記憶中
5. **代碼風格** - Hooks 腳本應遵循 PowerShell 或 Bash 最佳實踐

## 🔗 相關資源

- [VS Code Copilot 自定義 Agents](https://code.visualstudio.com/docs/copilot/customization/custom-agents)
- [VS Code Copilot Hooks](https://code.visualstudio.com/docs/copilot/customization/hooks)
- [Model Context Protocol (MCP)](https://modelcontextprotocol.io/)

## 📝 許可證

This project is for demonstration purposes.

---

**上次更新**: 2026-03-16