# 🧪 測試部署指南

感謝對本項目的測試！本指南幫助你快速設置和測試多 Agent 系統。

## 📋 系統要求

- **VS Code** (最新版本)
- **GitHub Copilot** 訂閱
- **Git** (用於 clone)
- **Windows/macOS/Linux** 任一系統

## 🚀 5 分鐘快速部署

### 步驟 1: Clone 項目

```bash
git clone https://github.com/[owner]/multi_agent_system.git
cd multi_agent_system
```

### 步驟 2: 打開 VS Code

```bash
code .
```

### 步驟 3: 等待 Copilot 載入

打開 VS Code 後，系統會自動：
- ✅ 掃描 `.github/agents/` 中的 Agents
- ✅ 加載 Hooks 配置
- ✅ 準備記憶系統

**檢查清單** (2-3 秒內完成):
- [ ] 沒有錯誤信息
- [ ] Copilot 圖標在左邊欄可見

### 步驟 4: 打開 Copilot Chat

按 `Ctrl+L` (Windows) 或 `Cmd+L` (Mac) 打開 Copilot Chat

**預期結果:**
```
Chat 窗口打開
↓
頂部有 "Agents" 下拉菜單
```

### 步驟 5: 選擇 Project Manager

點擊 Agents 下拉菜單，選擇 **"Project Manager"**

**預期結果:**
```
Chat 輸入框下方顯示:
"協調員 - 管理項目進度、分配任務、整合結果和記憶"
```

### 步驟 6: 提交第一個需求

複製以下提示到 Chat：

```
我有個新項目需要：
1. 爬取一個網站的數據
2. 設計一個數據模型來儲存
3. 創建一個簡單的儀表板

請檢查你的記憶系統，
看看是否有相關的過往經驗可以參考。
```

按 Enter 提交。

---

## 🔍 檢查清單：系統是否正確運行？

### ✅ 通過這些檢查來驗證系統工作正常

#### 檢查 1: Agents 自動檢測

**操作:**
1. 打開 Copilot Chat
2. 查看 Agents 下拉菜單

**預期結果:**
```
應看到 4 個 Agents:
✓ Project Manager
✓ Crawler Expert
✓ Database Expert
✓ Frontend Engineer
```

**如果失敗:** 
- 檢查 `.github/agents/` 目錄是否存在
- 檢查 4 個 `.agent.md` 文件是否都存在
- 重啟 VS Code

---

#### 檢查 2: 記憶自動加載

**操作:**
1. 選擇 Project Manager
2. 打開 Output 面板 (View → Output)
3. 選擇 "GitHub Copilot Chat Hooks" 頻道
4. 提交任何提示 (例如："你好")
5. 查看日誌

**預期結果:**
```
日誌中應包含:
[SessionStart] Loading project-state.json...
[SessionStart] Injecting context...
```

**如果失敗:**
- 檢查 `.github/hooks/hooks.json` 是否存在
- 檢查 `.github/memory/project-state.json` 是否有效 JSON
- 查看 Output 面板中的錯誤信息

---

#### 檢查 3: 已知問題被記住

**操作:**
1. 提交提示："我需要爬取 Dcard 股票版，需要怎樣解決 Proxy 被封禁的問題?"
2. 查看 PM 的回應

**預期結果:**
```
PM 應提到:
"根據我的記憶，上月遇到過 Proxy 被封禁的問題..."
"解決方案：使用 VPN 連接然後通過住宅代理輪換"
```

**如果失敗:**
- 檢查 `project-state.json` 中的 `known_issues` 字段
- 檢查 `crawler-memory.json` 中的 `solved_problems` 字段

---

#### 檢查 4: Agents 可互相調用

**操作:**
1. 選擇 PM
2. 提交: "請為我調用 Crawler Expert 來分析爬蟲需求"
3. 觀察 PM 是否推薦或調用其他 Agent

**預期結果:**
```
PM 應能:
✓ 識別需要其他 Agent
✓ 推薦調用 Crawler Expert
✓ 或直接調用 (如果支持)
```

**如果失敗:**
- 這是正常的，取決於 VS Code Copilot 版本對 `agent` 工具的支持

---

#### 檢查 5: 權限管理系統

**操作:**
1. 查看 `.github/tools/mcp-registry.json`
2. 查看 `.github/tools/TOOLS_MANIFEST.md`

**預期結果:**
```
✓ mcp-registry.json 包含官方、社區、自定義 MCPs
✓ TOOLS_MANIFEST.md 包含推薦列表
✓ PM_QUICK_REFERENCE.md 包含快速查詢卡
```

**如果失敗:**
- 重新 clone 項目
- 檢查文件完整性

---

## 📝 測試場景

### 場景 1: 基本協調 (5 分鐘)

**目標:** 驗證 PM 能查閱記憶並制定計劃

**步驟:**
```
1. 選擇 PM Agent
2. 提交: "我想開發一個爬蟲項目"
3. 觀察 PM 的回應
```

**預期結果:**
- PM 查閱記憶中的已知問題
- PM 提出包含多個 Agents 的計劃
- PM 提到過去的類似項目經驗

---

### 場景 2: Agent 記憶隔離 (5 分鐘)

**目標:** 驗證每個 Agent 有獨立的記憶

**步驟:**
```
1. 選擇 Crawler Expert
2. 提交: "我需要爬取新網站，注意 Proxy 問題"
3. 觀察 Crawler 是否提到過去的 Proxy 解決方案
```

**預期結果:**
- Crawler Expert 記住了上月的 Proxy 問題
- Crawler Expert 提出 VPN 解決方案
- 其他 Agents 不會訪問爬蟲記憶

---

### 場景 3: 權限檢查 (5 分鐘)

**目標:** 驗證 PM 能檢查工具權限

**步驟:**
```
1. 選擇 PM
2. 提交: "Crawler Expert 有 execute 工具嗎?我想讓他測試爬蟲"
3. 觀察 PM 的回應
```

**預期結果:**
- PM 查詢 `.github/tools/mcp-registry.json`
- PM 確認 Crawler Expert 有 `execute` 工具
- PM 或推薦 MCP，或確認可以調用

---

### 場景 4: MCP 推薦 (5 分鐘)

**目標:** 驗證 PM 能推薦 MCPs

**步驟:**
```
1. 選擇 PM
2. 提交: "我想為爬蟲專家增加 BeautifulSoup 功能，有什麼 MCP 可用?"
3. 觀察 PM 的回應
```

**預期結果:**
- PM 查詢 TOOLS_MANIFEST.md
- PM 推薦 BeautifulSoup MCP
- PM 提供集成建議

---

## 📊 測試報告模板

請用此模板報告測試結果：

```markdown
# 多 Agent 系統測試報告

**測試者**: [你的名字]
**測試日期**: [日期]
**OS**: [Windows/macOS/Linux]
**VS Code 版本**: [版本號]
**Copilot 訂閱**: [Yes/No]

## ✅ 通過的測試

- [ ] 檢查 1: Agents 自動檢測
- [ ] 檢查 2: 記憶自動加載
- [ ] 檢查 3: 已知問題被記住
- [ ] 檢查 4: Agents 互相調用
- [ ] 檢查 5: 權限管理系統

## ❌ 失敗或問題

### 問題 1
**描述**: [描述問題]
**重現步驟**: [如何重現]
**預期結果**: [應該發生什麼]
**實際結果**: [實際發生了什麼]
**屏幕截圖**: [如有，附上]

### 問題 2
[類似格式]

## 💡 建議和反饋

- [建議 1]
- [建議 2]
- [建議 3]

## 📝 其他備註

[任何其他你想分享的]
```

---

## 🆘 常見問題

### Q: 我看不到 4 個 Agents

**A:**
1. 確保 `.github/agents/` 目錄包含 4 個 `.agent.md` 文件
2. 重啟 VS Code (`Ctrl+Shift+P` → "Reload Window")
3. 如果仍然不行，檢查 `.agent.md` 文件的 YAML 格式是否有效

---

### Q: Hooks 似乎沒有執行

**A:**
1. 打開 Output 面板 (View → Output)
2. 選擇 "GitHub Copilot Chat Hooks"
3. 查看是否有錯誤信息
4. 檢查 `.github/hooks/hooks.json` 的 JSON 格式
5. 檢查 PowerShell 腳本的存在

---

### Q: PM 沒有提到已知的 Proxy 問題

**A:**
1. 檢查 `project-state.json` 是否包含 "PROXY-001"
2. 檢查 `crawler-memory.json` 是否包含相應的解決方案
3. 刪除舊的 session JSON 文件 (`.github/memory/session-*.json`)
4. 重新啟動 VS Code

---

### Q: 文件結構看起來不對

**A:**
1. 運行: `git status` 確保所有文件都被正確跟蹤
2. 運行: `find .github -type f` 列出所有文件
3. 確保沒有文件被 `.gitignore` 忽略

---

## 📧 反饋和支持

如果遇到任何問題：

1. **詳細記錄** - 使用上面的測試報告模板
2. **包含截圖** - 視覺化幫助診斷
3. **提供日誌** - 從 Output 面板複製 Hooks 日誌
4. **GitHub Issues** - 提交 Issue 到項目倉庫

---

## 🎓 進階測試 (可選)

### 自定義 Agent

嘗試修改 `.github/agents/` 中的 Agent 定義，看系統是否適應。

### 添加新記憶

在相關的 `*-memory.json` 中添加新的已知問題或解決方案，觀察 Agent 是否使用。

### 修改 Hooks

實驗修改 `.github/hooks/` 中的 PowerShell 腳本，嘗試添加自定義邏輯。

### 集成實際 MCP

根據 `TOOLS_MANIFEST.md` 的指南，嘗試集成真實的 MCP (例如 Brave Search)。

---

**感謝測試！** 🙏

你的反饋對改進系統至關重要。

---

**版本**: 1.0  
**最後更新**: 2026-03-16
