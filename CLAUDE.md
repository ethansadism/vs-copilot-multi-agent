# Claude Code 全域規則

本專案使用 **Basic Memory MCP** 管理知識，記憶以 Markdown 筆記存放於 `memory-kb/`。

## 雙模式運作

本專案的 Claude Code 有兩種運作模式，由 SessionStart hook 預設為一般模式：

### 一般對話模式（預設）

你以全方位 Agent 身份運作，直接與使用者對話、寫程式碼、解決問題。

### PM 多 Agent 模式

使用者表達想啟動 PM 時（如「啟動 PM」「使用 PM」「PM 模式」等語意），切換至 PM 工作流程（見 `.claude/agents/pm.md`）。PM 模式下使用 `search_notes("project overview")` 等 PM 專用 SOP。

> 模式判斷靠語意理解，不需要精確關鍵字。

## 對話開始 SOP（每次新對話必做）

SessionStart hook 會自動顯示進行中的主題記憶選單和模式提示。

### 一般模式 SOP

當使用者詢問專案狀態、進度、想恢復上次對話、或說「繼續」「continue」時：

1. 呼叫 `recent_activity(timeframe="7d")`
2. 從結果中找 permalink 含 `conversations/` 的筆記，用 `read_note` 讀**最新**那筆
3. 同時檢查 `topics/_index.json` 中 status 為 `active` 的主題，有的話用 `read_note` 載入
4. 若 `conversations/` 無結果，才讀 recent_activity 清單的第一筆

> **注意**：`project/` 筆記每次開發都在更新，會永遠排在 `conversations/` 前面。直接讀第一筆通常讀到的是 PM 的架構筆記而非對話紀錄。一般模式下**不要**用 `project/` 筆記來回答進度問題。

### PM 模式 SOP

使用者啟動 PM 後，改用 `.claude/agents/pm.md` 中定義的標準工作流程：
- `search_notes("project overview")` 查詢專案狀態
- `search_notes("known issues")` 查詢已知問題
- 遵循 PM 的決策樹和任務分派流程

如果使用者選擇了某個主題，用 `read_note` 載入該主題的筆記。

## 記憶系統資料夾結構

```
memory-kb/
├── contracts/       ← 跨 agent 介面合約（PM 寫入，所有 agent 可讀）
├── conversations/   ← 跨角色重要對話紀錄（架構決策、重要會話摘要）
├── project/         ← 全域專案狀態（PM 維護）
├── crawler/         ← 爬蟲經驗
├── database/        ← 資料庫模型與查詢經驗
├── frontend/        ← UI/UX 與組件經驗
└── topics/          ← 主題記憶（對話主題分類儲存）
    ├── _index.json  ← 主題索引（名稱、狀態、建立時間）
    └── {topic-name}/
        └── *.md     ← 該主題的筆記
```

## 筆記命名規則（所有人適用）

### 一般筆記（crawler/ database/ frontend/ project/）

**`write_note` 的 `title` 格式：`{app-id}_{seq}_{name}`**

| 欄位 | 說明 | 範例 |
|------|------|------|
| `{app-id}` | app 縮寫；跨 app 通用筆記用 `general` | `mta_demo3`, `general` |
| `{seq}` | 3 位流水號 | `001`, `002` |
| `{name}` | kebab-case 簡述（全小寫、連字號） | `github-trending-crawler` |

**完整範例：**
- ✅ `mta_demo3_001_github-trending-crawler`
- ✅ `mta_demo2_001_twse-api-ssl-fallback`
- ✅ `general_001_best-practices`
- ❌ `GitHub Trending Crawler`（無前綴、有空格）
- ❌ `github-trending-crawler`（缺少 app 前綴）

### 對話紀錄（conversations/）

**`title` 格式：`{YYYY-MM-DD}_{seq}_{name}`**

| 欄位 | 說明 | 範例 |
|------|------|------|
| `{YYYY-MM-DD}` | 日期 | `2026-03-18` |
| `{seq}` | 當天流水號（2 位） | `01`, `02` |
| `{name}` | kebab-case 簡述 | `gap002-fix` |

**完整範例：**
- ✅ `2026-03-18_01_gap002-fix`
- ✅ `2026-03-18_02_readme-update`

### 介面合約（contracts/）

**由 PM 建立，所有 agent 可讀。**

**`title` 格式：`{app-id}_{seq}_contracts`**

| 欄位 | 說明 | 範例 |
|------|------|------|
| `{app-id}` | app 縮寫 | `mta_demo4` |
| `{seq}` | 3 位流水號 | `001` |

**完整範例：**
- ✅ `mta_demo4_001_contracts`
- ✅ `mta_demo4_002_ws-contracts`（當同一 app 有多份合約時）

**必填 tags：** `["app:{app-id}", "agent:pm", "type:contract"]`

> 合約筆記是跨 session 持久的。新 session 的 PM 應在 Step 1 用 `search_notes("contracts", tags=["app:xxx", "type:contract"])` 查詢現有合約。

### 主題筆記（topics/{topic-name}/）

**`title` 格式：`{seq}_{name}`**

| 欄位 | 說明 | 範例 |
|------|------|------|
| `{seq}` | 3 位流水號 | `001`, `002` |
| `{name}` | kebab-case 簡述 | `initial-design` |

**完整範例：**
- ✅ `001_initial-design`
- ✅ `002_hook-migration-decision`

## Tag 規範（write_note 必填）

```
tags: ["app:mta_demo3", "agent:crawler", "experience"]
```

| Tag | 格式 | 說明 |
|-----|------|------|
| app | `app:mta_demo3` | 與特定 app 關聯；跨 app 通用筆記用 `app:general` |
| agent | `agent:claude` / `agent:pm` / `agent:crawler` / `agent:database` / `agent:frontend` | 筆記撰寫者（一般對話用 `agent:claude`，PM 及 subagent 用對應角色） |
| type | `bug` / `experience` / `reference` / `session` / `contract` / `topic` | 筆記性質 |

> **PreToolUse hook 會自動驗證**：write_note 呼叫如果缺少 `app:` 或 `agent:` tag，會被阻擋（exit 2）。

## 精確搜尋

```
# 鎖定特定 app（比純語意搜尋更精確，不會跨 app 混淆）
search_notes("關鍵字", tags=["app:mta_demo3"])

# 鎖定特定 agent 的筆記
search_notes("關鍵字", tags=["agent:crawler"])
```

## Observations 必填欄位

每筆筆記的 Observations 必須包含：
- `app :: mta_demo3`（或 `general`）
- `agent :: crawler`（撰寫者）

## PM 派任務格式（強制）

PM 呼叫 subagent 時，任務描述**開頭必須**包含當前 app 名稱：

```
[當前 app: mta_demo4]
任務：實作美股爬蟲...
```

這讓 subagent 知道 `search_notes` 該用 `tags=["app:mta_demo4"]`。

## 主題記憶系統

### 關鍵字觸發儲存

當使用者的訊息包含以下關鍵字時（由 UserPromptSubmit hook 偵測），會自動注入儲存提示：
- 「筆記」「記一下」「記錄進度」「記錄一下」「存起來」「save」「note」

觸發後，請：
1. 詢問使用者要存入哪個主題（或建立新主題）
2. 用 `write_note` 寫入 `topics/{topic-name}/` 資料夾
3. 更新 `topics/_index.json` 的主題狀態

### 主題狀態

- **active** — 進行中，會在 SessionStart 選單顯示
- **archived** — 封存，不自動載入，節省 token

### 封存主題

使用者說「封存 {主題名}」時，將 `_index.json` 中該主題狀態改為 `archived`。
