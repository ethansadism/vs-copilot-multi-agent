# 快速開始指南

## ⚡ 30 秒開始使用

### 1️⃣ 打開項目

```bash
# 在 VS Code 中打開 workspace
code c:\code\projects\multi_agent_system
```

### 2️⃣ 打開 Copilot Chat

- 按 `Ctrl+L` 或點擊左側邊欄的 Copilot 圖標

### 3️⃣ 選擇 Agent

- 點擊 Chat 頂部的 **Agents** 下拉菜單
- 選擇 **"Project Manager"**

### 4️⃣ 提交需求

```
我需要爬取三個新網站，準備新的 Dashboard 
```

### 5️⃣ 觀察 PM 的記憶加載

- PM 會提到已知的 Proxy 問題和解決方案
- PM 會提出包括其他 Agents 的計劃

✅ **完成！** 系統已啟動。

---

## 📚 文檔

- **[README.md](README.md)** - 完整架構說明
- **[DEMO_GUIDE.md](DEMO_GUIDE.md)** - 詳細演示指南
- **[.github/agents/](./github/agents/)** - Agent 定義
- **[.github/memory/](./github/memory/)** - 記憶文件

---

## 🎯 核心概念

### 四個 Agents

| Agent | 角色 | 記憶文件 |
|-------|------|--------|
| **Project Manager** | 協調員 | project-state.json |
| **Crawler Expert** | 爬蟲專家 | crawler-memory.json |
| **Database Expert** | 數據庫專家 | database-memory.json |
| **Frontend Engineer** | 前端工程師 | frontend-memory.json |

### 關鍵特性

- 🧠 **永久記憶** - 每個 Agent 有獨立的記憶庫
- 🔄 **自動工作流** - Hooks 在關鍵點執行
- 🛡️ **錯誤避免** - Agent 查閱記憶避免重複問題
- 📊 **審計日誌** - 所有操作都被記錄

---

## 🚀 下一步

1. **閱讀 [DEMO_GUIDE.md](DEMO_GUIDE.md)** 了解完整演示流程
2. **修改 Agent 指令** 在 `.github/agents/` 中自定義
3. **更新記憶** 在 `.github/memory/` 中添加你的經驗
4. **添加自定義 Hooks** 擴展自動化功能

---

## 🔗 資源

- [VS Code Copilot 自定義 Agents](https://code.visualstudio.com/docs/copilot/customization/custom-agents)
- [VS Code Copilot Hooks](https://code.visualstudio.com/docs/copilot/customization/hooks)

---

**準備好了嗎？** 👉 打開 VS Code，選擇 Project Manager，開始對話吧！
