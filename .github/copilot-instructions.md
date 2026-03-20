# Copilot 全域規則

本專案使用 **Basic Memory MCP** 管理知識，記憶以 Markdown 筆記存放於 `memory-kb/`。

## 對話開始 SOP（每次新對話必做）

當用戶說「繼續」、「continue」或要求恢復上次對話時：

1. 呼叫 `recent_activity(timeframe="7d")`
2. **讀回傳清單的第一筆**（修改時間最新），這就是最新的對話狀態
3. 不要自行判斷哪筆「看起來」更重要，第一筆就是答案

> **錯誤示範**：recent_activity 回傳 5 筆，選了第 5 筆而非第 1 筆。

## 記憶系統資料夾結構

```
memory-kb/
├── contracts/   ← 跨 agent 介面合約（PM 寫入，所有 agent 可讀）
├── conversations/   ← 跨角色重要對話紀錄（架構決策、重要會話摘要）
├── project/         ← 全域專案狀態（PM 維護）
├── crawler/         ← 爬蟲經驗
├── database/        ← 資料庫模型與查詢經驗
└── frontend/        ← UI/UX 與組件經驗
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
- ❓ `2026-03-18_basic-memory-install-and-rules`（缺少 seq，同天多個會衝突）

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
- ❌ `mta_demo4_001_interface-contracts`（太冗長）

**必填 tags：** `["app:{app-id}", "agent:pm", "type:contract"]`

> 合約筆記是跨 session 持久的。新 session 的 PM 應在 Step 1 用 `search_notes("contracts", tags=["app:xxx", "type:contract"])` 查詢現有合約。

## Tag 規範（write_note 必填）

```
tags: ["app:mta_demo3", "agent:crawler", "experience"]
```

| Tag | 格式 | 說明 |
|-----|------|------|
| app | `app:mta_demo3` | 與特定 app 關聯；跨 app 通用筆記用 `app:general` |
| agent | `agent:crawler` / `agent:database` / `agent:frontend` / `agent:pm` | 筆記撰寫者 |
| type | `bug` / `experience` / `reference` / `session` / `contract` | 筆記性質 |

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
沒有這一行，hook 注入的 `<app-id>` 佔位符無法被正確替換。
