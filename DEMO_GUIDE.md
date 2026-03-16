# 多 Agent 協作系統 - 完整演示指南

## 📋 演示準備

### 所需環境
- VS Code（最新版本）
- GitHub Copilot 訂閱
- Windows/macOS/Linux

### 文件結構驗證

在開始演示前，請確認以下文件存在：

```
✓ .github/agents/pm.agent.md
✓ .github/agents/crawler.agent.md
✓ .github/agents/database.agent.md
✓ .github/agents/frontend.agent.md

✓ .github/memory/project-state.json
✓ .github/memory/crawler-memory.json
✓ .github/memory/database-memory.json
✓ .github/memory/frontend-memory.json

✓ .github/hooks/hooks.json
✓ .github/hooks/session-init.ps1
✓ .github/hooks/subagent-start.ps1
✓ .github/hooks/subagent-stop.ps1
✓ .github/hooks/post-tool-use.ps1
✓ .github/hooks/log-prompt.ps1
```

---

## 🎬 演示流程

### 第 1 步：打開 VS Code

1. 打開 VS Code
2. 打開此 workspace（`c:\code\projects\multi_agent_system`）
3. 使用 `Ctrl+Shift+P` 打開命令面板

### 第 2 步：查看加載的 Agents

1. 打開 Copilot Chat（`Ctrl+L` 或點擊 Copilot 圖標）
2. 在 Chat 窗口頂部，點擊 **Agents** 下拉菜單
3. 應該看到 4 個 Agent：
   - Project Manager
   - Crawler Expert
   - Database Expert
   - Frontend Engineer

**預期結果**：所有 Agent 都應該出現在列表中

### 第 3 步：選擇 Project Manager

1. 從 Agents 下拉菜單選擇 **"Project Manager"**
2. 在 Chat 輸入框中應該看到描述："協調員 - 管理項目進度、分配任務、整合結果和記憶"

### 第 4 步：提交初始請求

**輸入以下消息**：

```
你好，我需要進行一個新的項目：
1. 爬取 3 個新網站的數據（StackOverflow、GitHub、Product Hunt）
2. 設計新的數據模型來存儲這些數據
3. 創建一個新的儀表板來可視化這些數據

請告訴我你的計劃，並注意避免上個月遇到過的 Proxy 問題。
```

**預期行為**：

- ✅ PM Agent 查閱了項目記憶（通過 SessionStart Hook）
- ✅ PM 在回應中提到了已知的 Proxy 問題和解決方案
- ✅ PM 制定了包括 3 個 Subagent 的計劃

**PM 的典型回應應包括**：
```
# 項目分析和計劃

我已經查閱了我們的項目記憶。我看到上個月我們遇到了 Proxy 被封禁的問題，
已通過使用 VPN 解決。

## 建議的執行計劃

1. **爬蟲專家任務** - 爬取三個網站
   - StackOverflow：需要認證
   - GitHub：API 限制
   - Product Hunt：有反爬蟲機制
   - **注意**：使用 VPN 避免 IP 被封禁

2. **數據庫專家任務** - 設計新的 ORM 模型
   - 應支持多個來源的異構數據
   - 需要考慮未來擴展

3. **前端工程師任務** - 創建新儀表板
   - 為每個數據源設計圖表
   - 實現實時更新功能

讓我立即派遣專家們執行...
```

### 第 5 步：調用爬蟲專家

**用戶指令**（基於 PM 的建議）：

```
@爬蟲專家：請設計和實現爬取 StackOverflow、GitHub 和 Product Hunt 的爬蟲，
特別注意使用 VPN 避免 IP 被封禁。
```

**預期行為**：

- ✅ 切換到 Crawler Expert Agent
- ✅ Crawler Agent 加載其記憶（通過 SubagentStart Hook）
- ✅ Crawler Agent 在回應中提到上月的 Proxy 解決方案
- ✅ Crawler Agent 提出詳細的爬蟲實現計劃

**Crawler Expert 的典型回應**：
```
## 爬蟲專家報告

我已加載我的記憶。我看到上月關於 Proxy 被封禁的問題已通過 VPN 解決。

### 計劃

1. **StackOverflow** - 需要認證
   - 實現會話管理
   - 使用 VPN + 代理輪換

2. **GitHub** - 使用 API
   - 通過 GitHub Token 認證
   - 查詢限制 60 requests/minute

3. **Product Hunt** - 有反爬蟲機制
   - 使用 Selenium 進行 JavaScript 渲染
   - 實現 2-3 秒的請求延遲

### 我將生成以下文件
- `scrapers/stackoverflow_crawler.py`
- `scrapers/github_crawler.py`
- `scrapers/producthunt_crawler.py`
- `.github/reports/crawler-report-20260316_120000.md`
```

### 第 6 步：調用數據庫專家

**用戶指令**：

```
@數據庫專家：請設計 ORM 模型來存儲來自三個來源的數據
（StackOverflow 帖子、GitHub 倉庫、Product Hunt 產品），
並考慮未來可能添加更多數據源。
```

**預期行為**：

- ✅ 切換到 Database Expert Agent
- ✅ Database Agent 加載其記憶
- ✅ Database Agent 提出數據模型設計

**Database Expert 的典型回應**：
```
## 數據庫專家報告

我已加載設計模式記憶。基於過去的經驗，我建議...

### 建議的 ORM 模型

```python
class DataSource(Base):
    """數據源基類"""
    id = Column(Integer, primary_key=True)
    type = Column(String, enum=['stackoverflow', 'github', 'producthunt'])
    
class StackOverflowPost(Base):
    """StackOverflow 帖子模型"""
    id = Column(Integer, primary_key=True)
    title = Column(String)
    content = Column(Text)
    source = relationship("DataSource")
    
# ... 更多模型
```

### 遷移計畫
1. 創建新表
2. 索引優化
3. 數據驗證規則

我將生成詳細的 SQLAlchemy 代碼和遷移腳本。
```

### 第 7 步：調用前端工程師

**用戶指令**：

```
@前端工程師：請為新的三個數據源設計和實現儀表板視圖，
包括數據分佈圖、趨勢線和實時更新功能。
```

**預期行為**：

- ✅ 切換到 Frontend Engineer Agent
- ✅ Frontend Agent 加載其記憶（設計系統）
- ✅ Frontend Agent 提出 UI/UX 和圖表設計

**Frontend Engineer 的典型回應**：
```
## 前端工程師報告

我已加載設計系統記憶。我將使用我們現有的 Segoe UI 字體和藍色主題。

### 新儀表板設計

#### 組件 1: StackOverflow 數據
- 「熱門問題」柱狀圖
- 「回答率趨勢」折線圖
- 即時更新

#### 組件 2: GitHub 數據
- 「倉庫星標分布」餅圖
- 「提交活動時間線」

#### 組件 3: Product Hunt 數據
- 「產品排名」排行表
- 「投票趨勢」面積圖

### 技術實現
使用 Chart.js 和實時 WebSocket 連接。

我將生成：
- HTML/CSS/JavaScript 代碼
- React 組件（如適用）
- 設計文檔
```

### 第 8 步：PM 收集報告

**回到 Project Manager，輸入**：

```
請收集爬蟲、數據庫和前端專家的報告，
並提供一個完整的項目完成狀態報告。
```

**預期行為**：

- ✅ PM 讀取所有 SubAgent 的報告
- ✅ PM 整合結果並識別依賴關係
- ✅ PM 更新項目記憶
- ✅ PM 提供最終的完成狀態

**PM 的最終報告**：
```
## 項目完成報告

### 完成狀態: ✅ 成功

#### 1. 爬蟲專家 (Crawler Expert)
- ✅ 三個爬蟲已實現
- ✅ VPN + 代理輪換已配置
- ⚠️ GitHub API 需要認證令牌

#### 2. 數據庫專家 (Database Expert)  
- ✅ ORM 模型已設計
- ✅ 遷移腳本已生成
- ✅ 備份策略已制定

#### 3. 前端工程師 (Frontend Engineer)
- ✅ 儀表板布局已完成
- ✅ 圖表組件已實現
- ✅ 實時更新機制已集成

### 下一步行動
1. 配置 GitHub API Token
2. 測試爬蟲穩定性
3. 進行前端用戶測試

### 記憶已更新
所有專家的新發現和經驗都已記錄到他們的記憶文件中，
供下次相似任務使用。
```

---

## 🔍 驗證記憶系統工作

### 查看記憶加載

1. 打開 Output 面板（View → Output）
2. 選擇 **"GitHub Copilot Chat Hooks"** 頻道
3. 查看 Hook 執行日誌

**預期日誌應包括**：
```
[SessionStart] Loading project-state.json...
[SubagentStart] Loading crawler-memory.json for Crawler Expert...
[SubagentStop] Saving session log for Crawler Expert...
```

### 檢查更新的記憶

1. 打開 `.github/memory/session-[SESSION_ID].json`
2. 應該看到所有完成的 Agents 列表

### 查看審計日誌

1. 打開 `.github/logs/prompts-YYYY-MM-DD.log`
2. 應該看到所有用戶提示的記錄

---

## 💡 演示要點總結

### 展示的關鍵特性

1. ✅ **Agent 自動檢測** - VS Code 自動發現 `.agent.md` 文件
2. ✅ **記憶自動加載** - SessionStart Hook 在會話開始時加載記憶
3. ✅ **分工明確** - 每個 Agent 有獨立的記憶和專業領域
4. ✅ **問題避免** - Crawler Agent 在報告中提及 Proxy 解決方案
5. ✅ **會話審計** - 所有對話和工具使用都被記錄
6. ✅ **工作流自動化** - Hooks 在關鍵點自動執行

### 用戶體驗流程

```
打開 VS Code
    ↓
    所有 Agents 自動加載
    ↓
選擇 PM Agent
    ↓
提交需求
    ↓
    ProjectStart Hook → 加載項目記憶
    ↓
PM 查閱記憶並制定計劃
    ↓
用戶選擇 Subagent
    ↓
    SubagentStart Hook → 加載 Agent 記憶
    ↓
Subagent 執行任務（已知問題對避免）
    ↓
    SubagentStop Hook → 保存進度
    ↓
PM 收集報告並更新項目記憶
    ↓
完成
```

---

## 🎯 演示常見問題

### Q: 為什麼我看不到新的 Agents？
A: 
- 檢查 `.agent.md` 文件是否正確放置在 `.github/agents/` 目錄
- 重啟 VS Code
- 檢查 Output 面板中的 diagnostics

### Q: Hooks 沒有執行？
A:
- 打開 Output → "GitHub Copilot Chat Hooks" 查看錯誤
- 檢查 PowerShell 腳本的語法
- 確保 `hooks.json` 在 `.github/hooks/` 目錄中

### Q: 記憶沒有加載？
A:
- 檢查 JSON 文件格式是否有效
- 使用 `jq` 或在線 JSON 驗證工具檢查
- 查看 SessionStart Hook 的日誌

---

## 📸 建議的演示截圖/操作

1. **截圖 1**: Agents 下拉菜單，顯示 4 個 Agents
2. **截圖 2**: PM 的初始規劃回應
3. **截圖 3**: Crawler Expert 提及已知 Proxy 問題
4. **截圖 4**: Output 面板中的 Hook 日誌
5. **截圖 5**: 更新的記憶文件

---

## ✅ 演示結束檢查清單

- [ ] 所有 4 個 Agents 正確加載
- [ ] SessionStart Hook 執行並加載記憶
- [ ] SubagentStart Hook 為 Agents 加載特定記憶
- [ ] 所有 Agent 都能訪問各自的記憶
- [ ] 會話日誌已生成
- [ ] 審計日誌有記錄

---

**演示完成！** 🎉

這個系統完全展示了：
✅ 基於 VS Code Copilot 的多 Agent 架構  
✅ 永久記憶系統和自動化工作流  
✅ 清晰的分工和角色定義  
✅ 問題記憶和避免重複錯誤的能力
