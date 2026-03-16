# 🛠️ Tools & Skills Manifest

用於 PM 查詢和管理各 Agent 的工具和 MCP/Skills。

## 工具矩陣

### Core Tools (基礎工具)

| 工具 | 類別 | 功能 | 必要性 | 說明 |
|------|------|------|-------|------|
| `read` | I/O | 讀取文件 | ⭐⭐⭐ | 所有 Agents 必需 |
| `edit` | I/O | 編輯文件 | ⭐⭐⭐ | 代碼生成必需 |
| `search` | 查詢 | 搜索代碼 | ⭐⭐ | 參考查詢 |
| `execute` | 執行 | 運行命令 | ⭐⭐ | 測試和驗證 |
| `agent` | 協調 | 調用其他 Agents | ⭐⭐ | 僅 PM 需要 |

### Python MCP Tools (推薦)

| MCP | 用途 | Agents | 狀態 |
|-----|------|--------|------|
| `pylance-mcp-server/*` | Python 智能提示 | Crawler, Database | 🔴 可選 (節省 token) |
| `python` | 執行 Python | Crawler, Database | 🟢 推薦 |
| `file-mcp` | 文件操作 | 所有 | 🟢 推薦 |

### 建議的 MCP Services

```json
{
  "crawler_mcp": {
    "name": "Web Crawler MCP",
    "provides": ["requests", "beautifulsoup4", "selenium", "proxy-rotation"],
    "for_agents": ["Crawler Expert"],
    "priority": "high"
  },
  "database_mcp": {
    "name": "Database MCP",
    "provides": ["sqlalchemy", "alembic", "migration-utils"],
    "for_agents": ["Database Expert"],
    "priority": "high"
  },
  "frontend_mcp": {
    "name": "Frontend MCP",
    "provides": ["chart-libs", "ui-components", "accessibility-tools"],
    "for_agents": ["Frontend Engineer"],
    "priority": "medium"
  },
  "code_review_mcp": {
    "name": "Code Review MCP",
    "provides": ["linting", "testing", "performance-analysis"],
    "for_agents": ["All Agents"],
    "priority": "medium"
  }
}
```

## 工具開放流程

### 場景 1: Agent 需要新工具

```
Agent: "我需要 [工具名稱] 來完成 [任務]"
  ↓
PM: "讓我檢查..."
  ├─ 查詢 MCP 資源庫
  ├─ 提出可用選項
  └─ 建議最佳實踐
  ↓
PM 向用戶報告:
  ├─ 所需工具: [名稱]
  ├─ 用途: [說明]
  ├─ 安全性: [評估]
  └─ 建議: [開放/拒絕/替代方案]
  ↓
用戶決策
  ├─ 直接開放
  ├─ 開放但有限制
  └─ 拒絕並提供替代
```

### 場景 2: PM 檢查 Subagent 權限

```
PM: "我要調用 Crawler Expert 進行 [任務]"
  ↓
PM 檢查流程:
  1. 任務所需工具: [工具列表]
  2. Crawler Expert 現有工具: [工具列表]
  3. 缺失工具: [如有]
  ↓
如果有缺失:
  ├─ 報告缺失: "需要 [工具] 才能完成"
  ├─ 查詢 MCP 庫: "有 MCP 提供此功能"
  └─ 建議: "建議開放 [工具] 或使用 [MCP]"
  ↓
如果無缺失:
  ├─ 確認: "✓ Crawler Expert 具備所需權限"
  └─ 執行: 調用 Subagent
```

## Per-Agent 權限等級

### PM (Project Manager)
```yaml
Current Tools: ['execute', 'read', 'edit', 'search', 'agent']
Suggested Addition:
  - 'file-mcp' (文件操作，管理記憶)
  - 'mcp-registry' (查詢 MCP 庫)
Max Recommended: 7 tools
```

### Crawler Expert
```yaml
Current Tools: ['read', 'edit', 'execute', 'search']
Suggested Addition (按優先級):
  1. 'ms-python.python' (Python 智能提示) - 可選
  2. MCP: 'crawler-mcp' (爬蟲特定功能)
Max Recommended: 6 tools
```

### Database Expert
```yaml
Current Tools: ['read', 'edit', 'search']
Suggested Addition (按優先級):
  1. 'ms-python.python' (Python 智能提示) - 可選
  2. MCP: 'database-mcp' (數據庫工具)
  3. 'execute' (測試遷移)
Max Recommended: 6 tools
```

### Frontend Engineer
```yaml
Current Tools: ['read', 'edit', 'search']
Suggested Addition (按優先級):
  1. MCP: 'frontend-mcp' (UI 組件庫)
Max Recommended: 4 tools
```

## MCP 資源推薦

### 官方推薦 MCPs

| MCP 名稱 | 功能 | 集成難度 | 節省 token | 推薦度 |
|---------|------|--------|----------|--------|
| **Brave Search MCP** | Web 搜索 | 易 | 高 | ⭐⭐⭐ |
| **GitHub MCP** | GitHub 操作 | 中 | 中 | ⭐⭐⭐ |
| **Postgres MCP** | 數據庫操作 | 中 | 高 | ⭐⭐⭐ |
| **Docker MCP** | 容器化 | 中 | 高 | ⭐⭐ |
| **Git MCP** | 版本控制 | 易 | 中 | ⭐⭐⭐ |

### 社區推薦 MCPs (Node Ecosystem)

- **npm-mcp** - NPM 包管理
- **typescript-mcp** - TypeScript 工具
- **jest-mcp** - 測試框架
- **webpack-mcp** - 打包工具

### 社區推薦 MCPs (Python Ecosystem)

- **pip-mcp** - Python 包管理
- **pytest-mcp** - 測試框架
- **django-mcp** - Django 工具
- **fastapi-mcp** - FastAPI 框架
- **pandas-mcp** - 數據分析
- **beautifulsoup-mcp** - 網頁爬蟲

## 如何集成新 MCP

### 步驟 1: PM 查詢
```
PM: "我們需要 [功能]，有合適的 MCP 嗎？"
  ↓ 搜索此文檔和官方 MCP 註冊表
  
結果: 找到 [MCP 名稱]
  - 功能: [詳細說明]
  - 安全性: [評估]
  - 集成成本: [token/複雜度]
```

### 步驟 2: 集成測試
```
測試內容:
  ✓ 功能測試
  ✓ 權限檢查
  ✓ Token 消耗估算
  ✓ 錯誤處理
```

### 步驟 3: 部署
```
更新步驟:
  1. 添加到 .github/tools/mcp-registry.json
  2. 更新相關 Agent 配置
  3. 測試 Agents 可正常使用
  4. 文檔更新
```

## 權限請求模板

當 Agent 需要新工具時，應向 PM 報告：

```markdown
# 工具請求

**Agent**: [Agent 名稱]
**任務**: [任務描述]
**所需工具**: [工具名稱]
**用途**: [具體用途]
**替代方案**: [如有]
**優先級**: [高/中/低]
**估計 Token 消耗**: [多少增加]

---

## 理由
[詳細解釋為什麼需要此工具]

## 安全性檢查
- 是否會訪問敏感數據? [是/否]
- 是否需要外部認證? [是/否]
- 是否會修改系統文件? [是/否]

## 建議
[PM 的建議]
```

## 權限開放檢查清單

為用戶開放新工具前，PM 應檢查：

- [ ] 工具功能明確且必要
- [ ] 沒有安全隱患
- [ ] 沒有更輕量的替代方案
- [ ] Agent 已理解工具的限制
- [ ] 已記錄權限開放原因
- [ ] 已更新記憶文件

## 記憶更新

每次開放新工具，PM 應更新：

```json
{
  "agent_name": "Crawler Expert",
  "permission_history": [
    {
      "date": "2026-03-16",
      "tool": "ms-python.python",
      "reason": "Python 代碼智能完成",
      "requested_by": "Crawler Expert",
      "approved_by": "PM",
      "status": "active"
    }
  ]
}
```

---

**最後更新**: 2026-03-16  
**下次審查**: 2026-04-16
