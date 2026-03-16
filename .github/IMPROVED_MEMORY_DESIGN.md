# 改進的記憶系統設計

為了讓 PM 真正執行標準流程，記憶系統需要這樣組織：

---

## 📁 目錄結構

```
.github/memory/
├── project-state.json              # 全局狀態（最重要）
├── 
├── agents/
│   ├── crawler-memory.json
│   ├── database-memory.json
│   └── frontend-memory.json
│
├── issues/
│   ├── known-issues.json           # 已知問題庫
│   └── solutions.json               # 解決方案庫
│
└── sessions/
    ├── session-YYYYMMDD-001.json   # 每個會話的記錄
    └── ...
```

---

## 📄 project-state.json 標準格式

```json
{
  "project_name": "Multi-Agent Web Crawler Dashboard",
  "current_phase": "Production",
  "last_update": "2026-03-16T10:00:00Z",
  
  "QUICK_REFERENCE": {
    "active_agents": ["Crawler Expert", "Frontend Engineer", "Database Expert"],
    "critical_issues": ["PROXY-001", "JS-RENDER-001"],
    "recent_solutions": {
      "PROXY-001": "Use residential proxy rotation",
      "JS-RENDER-001": "Implement Selenium/Puppeteer"
    }
  },
  
  "active_tasks": [
    {
      "task_id": "TASK-001",
      "description": "Dcard stock crawler",
      "assigned_agents": ["Crawler Expert", "Frontend Engineer"],
      "status": "completed",
      "date_assigned": "2026-03-16",
      "date_completed": "2026-03-16"
    }
  ],
  
  "completed_tasks": [
    // 歷史任務
  ],
  
  "known_issues": [
    {
      "issue_id": "PROXY-001",
      "title": "IP Blocking Issue",
      "description": "...",
      "solution": "...",
      "date_solved": "2026-02-15",
      "agent_responsible": "Crawler Expert",
      "status": "SOLVED"
    }
  ],
  
  "system_status": {
    "database": "Ready",
    "frontend": "Ready", 
    "crawler_infrastructure": "Ready"
  }
}
```

---

## 🎯 PM 使用記憶的 3 個關鍵點

### 1. 快速查詢 (QUICK_REFERENCE)

PM 在任務開始時應該立即看到：
- ✅ 當前有哪些活躍的 Agents
- ⚠️ 有哪些需要警告用戶的關鍵問題
- 💡 過去找到的解決方案

```python
# PM 應該這樣查詢：
quick_ref = memory["QUICK_REFERENCE"]
print(f"⚠️ 注意以下已知問題: {quick_ref['critical_issues']}")
```

### 2. Agent 專項記憶

當決定調用某個 Subagent 時，PM 應該查詢該 Agent 的記憶：

```python
# 調用爬蟲專家前
crawler_memory = read_file("crawler-memory.json")
print(f"已知問題: {crawler_memory['solved_problems']}")
print(f"最佳實踐: {crawler_memory['best_practices']}")
```

### 3. 任務歷史

PM 應該從過去的任務中學習：

```python
# 檢查相似任務是否在過去做過
similar_tasks = [t for t in memory["completed_tasks"] 
                 if "crawler" in t["description"].lower()]
```

---

## ✨ 改進的記憶更新流程

每次完成任務後，PM 應該這樣更新記憶：

```json
{
  "task_id": "TASK-002",
  "description": "Dcard stock crawler with dashboard",
  "assigned_agents": ["Crawler Expert", "Frontend Engineer", "Database Expert"],
  "status": "completed",
  "date_assigned": "2026-03-16",
  "date_completed": "2026-03-16",
  
  "execution_details": {
    "why_these_agents": "Task involves 3 domains: web scraping, UI design, and data storage",
    "problems_encountered": [
      "Dcard HTML structure changed",
      "Need JavaScript rendering"
    ],
    "solutions_applied": [
      "Fallback to demo data",
      "Note for future: Implement Selenium"
    ],
    "agents_performance": {
      "Crawler Expert": "High - implemented fallback gracefully",
      "Frontend Engineer": "High - beautiful dashboard with auto-refresh",
      "Database Expert": "N/A - simple JSON storage was sufficient"
    }
  },
  
  "new_known_issues": [
    {
      "issue_id": "DCARD-001",
      "title": "Dcard HTML structure change",
      "description": "Website may have changed HTML structure",
      "workaround": "Use demo data as fallback",
      "permanent_solution": "Implement Selenium/Puppeteer"
    }
  ]
}
```

---

## 🔄 PM 檢查清單與記憶的整合

| 清單項 | 對應的記憶操作 |
|-------|--------------|
| 查閱 project-state.json | 讀取 QUICK_REFERENCE 和 known_issues |
| 查閱爬蟲記憶 | 讀取 agents/crawler-memory.json |
| 識別已知問題 | 查詢 issues/known-issues.json |
| 記錄本次工作 | 更新 active_tasks 和 completed_tasks |
| 記錄新問題 | 添加到 known_issues |
| 記錄工作細節 | 創建 session-[ID].json |

---

## 💻 PM 初始化代碼模板

```python
# PM 會話開始時應該執行的步驟

import json
from datetime import datetime

class PMSession:
    def __init__(self):
        self.session_id = datetime.now().strftime("%Y%m%d-%H%M%S")
        self.memory = self.load_memories()
        self.checklist = self.print_checklist()
    
    def load_memories(self):
        """加載所有必要的記憶文件"""
        project_state = load_json("project-state.json")
        crawler_memory = load_json("agents/crawler-memory.json")
        frontend_memory = load_json("agents/frontend-memory.json")
        database_memory = load_json("agents/database-memory.json")
        
        return {
            "project": project_state,
            "crawler": crawler_memory,
            "frontend": frontend_memory,
            "database": database_memory
        }
    
    def print_checklist(self):
        """打印 PM 初始化檢查清單"""
        print("""
        ✅ PM 會話初始化清單
        [ ] 查閱 project-state.json 中的 QUICK_REFERENCE
        [ ] 了解當前活躍的 Agents
        [ ] 查看已知的關鍵問題
        [ ] 確認系統狀態
        [ ] 查閱相關 Agent 的記憶文件
        
        完成後，可以開始需求分析。
        """)
    
    def before_calling_subagent(self, agent_name):
        """調用 Subagent 前的檢查"""
        agent_memory = self.memory[agent_name.lower().split()[0]]
        print(f"""
        📌 調用 {agent_name} 前的提醒：
        • 已解決問題: {len(agent_memory['solved_problems'])}
        • 最佳實踐: {agent_memory['best_practices']}
        • 警告: [相關的已知問題]
        """)
    
    def save_session(self, task_info):
        """保存會話記錄"""
        session_file = f"sessions/session-{self.session_id}.json"
        save_json(session_file, task_info)
```

---

## 📊 記憶品質檢查表

PM 在更新記憶時應該檢查：

- [ ] QUICK_REFERENCE 是否最新？
- [ ] 新問題是否被正確分類？
- [ ] 解決方案是否清晰可復用？
- [ ] Agent 表現評分是否公正？
- [ ] 是否記錄了失敗原因（用於改進）？
- [ ] 是否有建議給未來的 PM？

---

**這個改進的記憶系統設計可以幫助 PM 真正遵守流程。**
