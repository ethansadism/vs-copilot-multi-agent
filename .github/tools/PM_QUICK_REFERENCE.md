# 🎫 PM 快速參考卡

## 📌 PM 的三大職責

### 1️⃣ 權限檢查 (在調用 Subagent 前)

```
任務: [描述]
  ↓
所需工具: [列表]
  ↓
查詢 Subagent 工具: .agent.md 第 3-4 行
  ↓
缺失工具? ─ 是 → 查詢 mcp-registry.json → 推薦 → 向用戶報告
         └ 否 → ✓ 可以調用
```

### 2️⃣ MCP 資源發現

```
用途: [Agents 需要什麼功能]
  ↓
查詢: .github/tools/TOOLS_MANIFEST.md (推薦 MCPs 部分)
或查詢: .github/tools/mcp-registry.json (結構化數據)
  ↓
評估:
  - 功能是否滿足?
  - Token 消耗是否可接受?
  - 集成難度是否可行?
  ↓
推薦給 Agent → 向用戶報告
```

### 3️⃣ 記憶維護

```
每次開放新工具:
  ↓
更新 .github/memory/project-state.json
  ├─ agent_permissions[]
  └─ mcp_usage[]
```

---

## 🔍 快速查詢指南

### 我想找 [功能] 的工具

**步驟**:
1. 打開 `.github/tools/TOOLS_MANIFEST.md`
2. 搜索 "MCP 資源推薦" 部分
3. 尋找相關功能的 MCP
4. 檢查推薦度 ⭐⭐⭐

**範例**:
```
我需要為 Crawler 找網頁解析工具
  → TOOLS_MANIFEST.md → BeautifulSoup MCP → ⭐⭐⭐ 推薦
  → 與 Crawler 兼容? ✓ 是
  → Token 影響? 高 (但值得)
  → 推薦開放
```

### [Agent] 需要新工具，我該做什麼?

**步驟**:
1. 查詢 `.github/tools/mcp-registry.json` 中的 `agent_capabilities`
2. 檢查 Agent 的 `recommended_mcps` 列表
3. 檢查 Agent 的 `max_tools` (最多能開多少)
4. 根據任務需求推薦最佳方案

**範例**:
```json
Agent: "Crawler Expert"
current_tools: 4 個
max_tools: 6 個
建議開放: 2 個額外工具

推薦順序:
  1. beautifulsoup-mcp (高優先級)
  2. pip-mcp (中優先級)
```

### 我要確認 [Agent] 能完成 [任務]

**步驟**:
1. 分析任務所需工具
2. 讀取 Agent 的 `.agent.md` 第 3 行 tools 部分
3. 檢查是否包含所有必要工具
4. 如缺失，查詢 MCP 資源庫

**檢查清單**:
```
任務: "爬取 Dcard 股票版"
所需: read, edit, execute, search
Crawler Expert 有?
  - read: ✓
  - edit: ✓
  - execute: ✓
  - search: ✓
結論: ✓ 可以調用
```

---

## 📊 Agent 工具矩陣速查

| Agent | 現有工具 | 上限 | 推薦添加 |
|-------|---------|------|---------|
| **PM** | 5 | 7 | `file-mcp` |
| **Crawler** | 4 | 6 | `beautifulsoup-mcp`, `pip-mcp` |
| **Database** | 3 | 6 | `execute`, `sqlalchemy-mcp` |
| **Frontend** | 3 | 4 | `chart-js-mcp` |

---

## 🎯 常見場景

### 場景 1: Crawler 說 "我需要 Proxy 工具"

```
你的檢查:
  1. 查詢 TOOLS_MANIFEST.md
  2. 看到 "Crawler Expert 記憶中有 Proxy 解決方案"
  3. 檢查 mcp-registry.json
  4. 沒有現成 MCP 提供 Proxy 工具
  
你的報告:
  ✓ Crawler 的記憶中已有 VPN + 代理輪換方案
  ✓ 可以先試用現有方案，無需新工具
  ✓ 如遇到問題，可查詢外部 MCP 或 API
```

### 場景 2: Database 說 "我需要執行 SQL 遷移"

```
你的檢查:
  1. Database 現有工具: read, edit, search
  2. 缺失: execute
  3. 查詢 mcp-registry.json
  4. 推薦: postgres-mcp
  
你的選擇:
  方案 A: 開放 execute 工具
  方案 B: 集成 postgres-mcp (更安全)
  
推薦: 方案 B (使用 postgres-mcp)
理由: 專用工具更安全，Token 消耗更少
```

### 場景 3: Frontend 說 "我要生成複雜圖表"

```
你的檢查:
  1. Frontend 現有: read, edit, search
  2. 查詢 mcp-registry.json
  3. chart-js-mcp (推薦度 ⭐⭐⭐)
  
你的報告:
  ✓ 推薦集成 chart-js-mcp
  ✓ Token 消耗: 中等
  ✓ 集成難度: 容易
  ✓ 預計節省: 大量 Token (不用手寫所有圖表代碼)
```

---

## 🔄 決策樹

```
Agent 需要新工具
  │
  ├─ 是否已在記憶中記錄? ─ 是 → 建議查詢記憶
  │                    └ 否 ↓
  │
  ├─ 檢查 MCP 資源庫
  │  │
  │  ├─ 有現成 MCP? ─ 是 → 推薦 MCP ✓
  │  │              └ 否 ↓
  │  │
  │  └─ 需要自定義工具?
  │     │
  │     ├─ 安全性可接受? ─ 否 → 尋找替代方案
  │     │                └ 是 ↓
  │     │
  │     ├─ Token 消耗合理? ─ 否 → 優化或拒絕
  │     │                 └ 是 ↓
  │     │
  │     └─ 向用戶報告並請求批准 → 更新工具 → 更新記憶
```

---

## 📋 周期性檢查清單

### 每週一次

- [ ] 查看 `mcp-registry.json` 中的新 MCPs
- [ ] 檢查是否有待處理的權限請求
- [ ] 審查 Agents 的工具使用情況

### 每月一次

- [ ] 更新 `TOOLS_MANIFEST.md` 中過時的 MCP 信息
- [ ] 評估現有 MCP 的效能和 Token 消耗
- [ ] 清理 `permission_requests` 列表

### 每季度一次

- [ ] 完整審查工具策略
- [ ] 評估是否需要新的自定義 MCP
- [ ] 優化 Agent 工具配置

---

## 🚨 紅旗警告

### ⚠️ 如果遇到以下情況，PM 應謹慎:

| 情況 | 風險 | 建議 |
|------|------|------|
| Agent 要求 `execute` + `edit` | 可能修改系統 | 限制範圍或使用 MCP |
| Agent 要求多個 Python 工具 | Token 消耗大 | 推薦 Python 相關 MCP |
| Agent 要求外部 API 存取 | 安全隱患 | 推薦官方 MCP (如 Brave Search) |
| Agent 頻繁請求新工具 | 設計問題 | 與 Agent 討論根本需求 |

---

## 📞 求助清單

### 我不確定 [工具] 是否安全

查看 `.github/tools/TOOLS_MANIFEST.md` 中的：
- "安全性檢查"部分
- 具體 MCP 的 "安全性" 字段

### 我想了解 [Agent] 能做什麼

查看：
1. `Agent.agent.md` 的描述部分
2. `mcp-registry.json` 中的 `agent_capabilities`
3. `.github/memory/` 中該 Agent 的記憶文件

### 我想記錄新開放的工具

更新 `.github/memory/project-state.json` 的 `agent_permissions` 部分：
```json
{
  "agent": "Crawler Expert",
  "tool": "beautifulsoup-mcp",
  "date_approved": "2026-03-16",
  "reason": "網頁解析",
  "approved_by": "User"
}
```

---

**最後更新**: 2026-03-16  
**適用版本**: v1.0+
