# Multi-Agent Collaboration System (v0.021)

基於 VS Code Copilot 的多 Agent 協作系統。PM 協調、專家執行、記憶持久化。

## 系統架構

### 四個 Agent 角色

| Agent | 職責 | 模型策略 | 關鍵 Frontmatter |
|-------|------|---------|-----------------|
| **Project Manager** | 協調分工、記憶管理 | 高階模型 | `agents: ['*']`, `disable-model-invocation: true` |
| **Crawler Expert** | 爬蟲開發、反爬蟲 | 低階優先 | `model: ["gpt-4o-mini", "gpt-4o"]` |
| **Database Expert** | 數據模型、遷移 | 低階優先 | `model: ["gpt-4o-mini", "gpt-4o"]` |
| **Frontend Engineer** | UI/UX、圖表 | 低階優先 | `model: ["gpt-4o-mini", "gpt-4o"]` |

### 核心機制

- **Subagent 編排** — PM 透過 `agents: ['*']` + `tools: ['agent']` 呼叫專家 agent
- **記憶自動注入** — SessionStart / SubagentStart Hook 機械式注入記憶到 context
- **記憶更新檢查** — Stop Hook 在會話結束前檢查是否已更新記憶
- **長對話保護** — PreCompact Hook 在 context 壓縮前重新注入關鍵資訊
- **省錢** — 專家 agent 用 `model` 陣列優先使用便宜模型，fallback 到高階

## 項目結構

```
.github/
├── agents/                  # Agent 定義（VS Code Copilot .agent.md 格式）
│   ├── pm.agent.md          # PM：agents=['*'], 頂層協調者
│   ├── crawler.agent.md     # 爬蟲專家
│   ├── database.agent.md    # 資料庫專家
│   └── frontend.agent.md    # 前端工程師
│
├── memory/                  # 永久記憶
│   ├── project-state.json   # 全局狀態 + 任務歷史 + 已知問題
│   ├── crawler-memory.json  # 爬蟲經驗
│   ├── database-memory.json # 資料庫經驗
│   └── frontend-memory.json # 前端經驗
│
├── hooks/                   # 7 個生命週期 Hook
│   ├── hooks.json           # Hook 配置
│   ├── session-init.sh      # SessionStart：注入全局記憶
│   ├── log-prompt.sh        # UserPromptSubmit：審計日誌
│   ├── subagent-start.sh    # SubagentStart：注入 agent 記憶
│   ├── subagent-stop.sh     # SubagentStop：記錄完成事件
│   ├── post-tool-use.sh     # PostToolUse：記錄工具使用
│   ├── pre-compact.sh       # PreCompact：壓縮前保護記憶
│   └── stop.sh              # Stop：提醒更新記憶
│
├── tools/                   # 工具管理
│   ├── TOOLS_MANIFEST.md    # 工具矩陣和 MCP 推薦
│   └── mcp-registry.json    # MCP 註冊表
│
├── reports/                 # Agent 任務報告
└── logs/                    # 審計日誌
```

## 快速開始

### 1. 打開項目

```bash
code /path/to/this/project
```

VS Code 會自動：
- 掃描 `.github/agents/` 載入所有 Agent
- 從 `.github/hooks/hooks.json` 載入 Hook 配置

### 2. 與 PM 對話

1. 打開 Copilot Chat（`Ctrl+L`）
2. 在 Agents 下拉菜單中選擇 **Project Manager**
3. 提交需求，例如：

```
我需要爬取 Dcard 股票版的數據，設計儲存模型，然後做一個 Dashboard 顯示前 10 支熱門股票。
```

### 3. PM 的標準工作流程

```
SessionStart Hook 自動注入記憶
  ↓
PM 展示專案背景和已知問題
  ↓
PM 分析需求，提出計劃（調用哪些 agent、為什麼）
  ↓
你確認計劃 ✓
  ↓
PM 並行調用 Subagents（各 agent 自動載入記憶）
  ↓
Subagents 各自：執行 → 測試 → 寫報告 → 更新記憶
  ↓
PM 收集報告，整合結果，更新全局記憶
  ↓
PM 向你報告完成狀態
  ↓
Stop Hook 檢查記憶是否已更新
```

## 記憶系統

### 核心概念

每個 Agent 有獨立的記憶檔案（JSON），Hook 在關鍵時刻自動注入到對話 context。

記憶中最有價值的是 **known_issues**（已知問題和解決方案）。例如：
- PROXY-001：IP 被封 → 用 VPN 解決
- DCARD-001：HTML 結構變動 → 用 demo data 降級

新的 agent 在任務開始時會自動看到這些問題，避免重複犯錯。

### 記憶更新時機

| Hook | 動作 |
|------|------|
| SessionStart | 注入 project-state.json |
| SubagentStart | 注入對應 agent 的 memory.json |
| PreCompact | context 壓縮前重新注入關鍵資訊 |
| Stop | 提醒更新記憶（如果未更新） |

## 模型配置

`model` 欄位接受陣列，VS Code 會按順序嘗試，不可用就 fallback：

```yaml
# 專家 agent — 優先用便宜模型
model: ["gpt-4o-mini", "gpt-4o"]

# PM — 需要推理能力
model: ["claude-sonnet-4", "gpt-4o", "o3-mini"]
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
