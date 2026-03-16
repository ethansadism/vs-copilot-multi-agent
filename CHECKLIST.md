# 實施檢查清單

## ✅ 文件和目錄驗證

### Agents 定義 (.github/agents/)

- [x] `pm.agent.md` - Project Manager
  - 名稱: "Project Manager"
  - 描述: "協調員 - 管理項目進度、分配任務、整合結果和記憶"
  - 工具: search, read
  
- [x] `crawler.agent.md` - Crawler Expert
  - 名稱: "Crawler Expert"
  - 描述: "爬蟲專家 - 開發和優化網站爬蟲，處理代理和反爬蟲問題"
  - 工具: search, read
  
- [x] `database.agent.md` - Database Expert
  - 名稱: "Database Expert"
  - 描述: "數據庫專家 - 設計數據模型、優化查詢、管理數據遷移"
  - 工具: search, read
  
- [x] `frontend.agent.md` - Frontend Engineer
  - 名稱: "Frontend Engineer"
  - 描述: "前端工程師 - 實現 UI/UX、設計圖表、優化視覺效果"
  - 工具: search, read

### 記憶系統 (.github/memory/)

- [x] `project-state.json` - 項目整體狀態
  - 包含: project_name, current_phase, active_tasks, known_issues, system_status
  - 已知問題: PROXY-001 (已解決)
  
- [x] `crawler-memory.json` - 爬蟲專家記憶
  - 包含: solved_problems, best_practices, crawled_websites, tools_and_libraries
  - 關鍵問題: Proxy 被封禁 → VPN 解決方案
  
- [x] `database-memory.json` - 數據庫專家記憶
  - 包含: designed_models, migration_experiences, performance_tips, backup_strategy
  
- [x] `frontend-memory.json` - 前端工程師記憶
  - 包含: design_system, implemented_charts, component_library, accessibility_notes

### Hooks 系統 (.github/hooks/)

- [x] `hooks.json` - Hooks 配置
  - SessionStart: session-init.ps1
  - UserPromptSubmit: log-prompt.ps1
  - PostToolUse: post-tool-use.ps1
  - SubagentStart: subagent-start.ps1
  - SubagentStop: subagent-stop.ps1
  
- [x] `session-init.ps1` - 會話初始化
  - 功能: 加載 project-state.json，注入上下文
  - 觸發: SessionStart
  
- [x] `subagent-start.ps1` - Subagent 啟動
  - 功能: 根據 Agent 類型加載對應記憶
  - 觸發: SubagentStart
  
- [x] `subagent-stop.ps1` - Subagent 完成
  - 功能: 記錄完成事件，保存會話日誌
  - 觸發: SubagentStop
  
- [x] `post-tool-use.ps1` - 工具後處理
  - 功能: 記錄工具使用情況
  - 觸發: PostToolUse
  
- [x] `log-prompt.ps1` - 提示記錄
  - 功能: 記錄用戶提示
  - 觸發: UserPromptSubmit

### 目錄結構

- [x] `.github/reports/` - 任務報告目錄
- [x] `.github/logs/` - 審計日誌目錄

### 文檔

- [x] `README.md` - 完整說明和使用指南
- [x] `QUICKSTART.md` - 30 秒快速開始
- [x] `DEMO_GUIDE.md` - 完整演示指南
- [x] `ARCHITECTURE.md` - 系統架構設計

---

## 🧪 功能驗證

### Agent 加載

- [ ] 打開 VS Code 中此 workspace
- [ ] 打開 Copilot Chat (`Ctrl+L`)
- [ ] 點擊 **Agents** 下拉菜單
- [ ] **預期**：看到以下 4 個 Agents
  - [ ] Project Manager
  - [ ] Crawler Expert
  - [ ] Database Expert
  - [ ] Frontend Engineer

### 記憶加載

- [ ] 選擇 **Project Manager**
- [ ] 打開 Output 面板 (`View → Output`)
- [ ] 選擇 **"GitHub Copilot Chat Hooks"** 頻道
- [ ] 提交提示："我有一個新的爬蟲項目"
- [ ] **預期**：看到以下日誌
  - [ ] `[SessionStart]` Hook 執行
  - [ ] 加載 `project-state.json` 成功

### Subagent 記憶

- [ ] PM 提出調用其他 Agents 的建議（或手動選擇）
- [ ] 選擇 **Crawler Expert**
- [ ] **預期**：Hooks 日誌顯示
  - [ ] `[SubagentStart]` Hook 執行
  - [ ] 加載 `crawler-memory.json` 成功
  - [ ] Crawler Expert 的回應中提到 Proxy 解決方案

### 工具記錄

- [ ] PM 或任何 Agent 使用搜索工具
- [ ] **預期**：
  - [ ] `[PostToolUse]` Hook 執行
  - [ ] 日誌文件 `.github/logs/tool-usage-[date].log` 被創建/更新

### 提示記錄

- [ ] 提交任何用戶提示
- [ ] **預期**：
  - [ ] `.github/logs/prompts-[date].log` 被創建/更新
  - [ ] 包含用戶提示和 session_id

---

## 📊 性能基準

### 啟動時間

- [ ] SessionStart Hook: < 2 秒
- [ ] SubagentStart Hook: < 1 秒
- [ ] PostToolUse Hook: < 0.5 秒

### 記憶大小

- [ ] project-state.json: < 50 KB
- [ ] 各 Agent 記憶: < 100 KB 每個
- [ ] 會話日誌: < 200 KB 每個

### 日誌檔案

- [ ] tool-usage-[date].log: < 1 MB 每天
- [ ] prompts-[date].log: < 500 KB 每天

---

## 🔧 故障排除

### 問題 1: Agent 未顯示

**症狀**: Agents 下拉菜單中看不到新 Agent

**檢查項**:
- [ ] 文件是否在 `.github/agents/` 目錄
- [ ] 文件名是否為 `.agent.md` 格式
- [ ] YAML frontmatter 是否正確（`---` 包圍）
- [ ] JSON 是否有效（使用 `jq` 驗證）
- [ ] VS Code 是否已重啟

**解決方案**:
```bash
# 驗證文件
ls .github/agents/
cat .github/agents/pm.agent.md

# 重新加載
# 在 VS Code 中：Ctrl+Shift+P → "Reload Window"
```

### 問題 2: Hooks 未執行

**症狀**: Output 面板中未見 Hook 日誌

**檢查項**:
- [ ] `hooks.json` 是否在 `.github/hooks/` 目錄
- [ ] PowerShell 腳本是否存在
- [ ] JSON 格式是否有效
- [ ] 事件名稱拼寫是否正確

**解決方案**:
```bash
# 驗證 JSON
jq empty .github/hooks/hooks.json

# 驗證文件權限（在 Linux/macOS）
chmod +x .github/hooks/*.ps1

# 檢查 Hooks 日誌
# VS Code Output 面板 → "GitHub Copilot Chat Hooks"
```

### 問題 3: 記憶未加載

**症狀**: Agent 不提及已知問題或解決方案

**檢查項**:
- [ ] JSON 文件格式是否有效
- [ ] 文件路徑是否正確
- [ ] Hook 是否正確返回 `additionalContext`
- [ ] Agent 指令是否要求參考記憶

**解決方案**:
```bash
# 驗證 JSON
jq empty .github/memory/*.json

# 手動檢查 Hook 輸出
powershell .github/hooks/session-init.ps1

# 檢查 Agent 指令
cat .github/agents/crawler.agent.md
# 應包含 "查閱 crawler-memory.json" 的指令
```

---

## 📝 自定義和擴展

### 添加新 Agent

1. 在 `.github/agents/` 中創建 `[name].agent.md`
2. 定義 YAML frontmatter：名稱、描述、工具
3. 編寫 Agent 指令
4. 在 `.github/memory/` 中創建對應的記憶文件
5. 在 `.github/hooks/hooks.json` 中添加規則（可選）

### 添加新 Hook

1. 編輯 `.github/hooks/hooks.json`
2. 添加新事件和對應的腳本
3. 創建 PowerShell/Bash 腳本
4. 測試 Hook 執行
5. 檢查 Output 面板中的日誌

### 更新記憶

1. 直接編輯 `.github/memory/[file].json`
2. 或讓 Hooks 自動更新（實現自動保存邏輯）
3. 驗證 JSON 格式有效

---

## 🚀 部署清單

準備在生產環境部署前：

- [ ] 所有 JSON 文件格式已驗證
- [ ] 所有 PowerShell 腳本已測試
- [ ] 記憶文件已備份
- [ ] Hooks 日誌目錄已創建
- [ ] 報告目錄已創建
- [ ] 文檔已更新
- [ ] 團隊已培訓
- [ ] 監控已設置

---

## 📞 支持

### 文檔參考

- **快速開始**: [QUICKSTART.md](QUICKSTART.md)
- **完整說明**: [README.md](README.md)
- **架構設計**: [ARCHITECTURE.md](ARCHITECTURE.md)
- **演示指南**: [DEMO_GUIDE.md](DEMO_GUIDE.md)

### 外部資源

- [VS Code Copilot Agents 文檔](https://code.visualstudio.com/docs/copilot/customization/custom-agents)
- [VS Code Copilot Hooks 文檔](https://code.visualstudio.com/docs/copilot/customization/hooks)
- [Model Context Protocol](https://modelcontextprotocol.io/)

---

**所有檢查項完成！系統已準備就緒。** ✅
