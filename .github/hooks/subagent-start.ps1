# SubagentStart Hook - 當 Subagent 啟動時注入 Basic Memory 記憶提示
# v0.02: 改用 Basic Memory MCP，不再直接讀 JSON

param(
    [Parameter(ValueFromPipeline=$true)]
    $input_json
)

try {
    $input = $input_json | ConvertFrom-Json
    $agent_type = $input.agent_type
    $agent_id = $input.agent_id
    $memory_kb = ".github/memory-kb"
    $log_dir = ".github/logs"

    # === 流程日誌 ===
    if (-not (Test-Path $log_dir)) { New-Item -ItemType Directory -Path $log_dir -Force | Out-Null }
    Add-Content -Path "$log_dir/hook-flow.log" -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [SubagentStart] >>> $agent_type (ID: $agent_id) spawned"

    # Agent 類型對應 memory-kb 資料夾
    $folder_map = @{
        "Crawler Expert"    = "crawler"
        "Database Expert"   = "database"
        "Frontend Engineer" = "frontend"
    }

    $agent_folder = $folder_map[$agent_type]

    # 列出該 agent 資料夾中的現有筆記
    $notes_list = ""
    if ($agent_folder -and (Test-Path "$memory_kb/$agent_folder")) {
        $notes = Get-ChildItem "$memory_kb/$agent_folder" -Filter "*.md" | Select-Object -ExpandProperty Name
        if ($notes) {
            $notes_list = ($notes | ForEach-Object { "  - $_" }) -join "`n"
        }
    }

    # 列出 contracts/ 共享合約筆記（所有 agent 皆可見）
    $contracts_list = ""
    if (Test-Path "$memory_kb/contracts") {
        $contracts = Get-ChildItem "$memory_kb/contracts" -Filter "*.md" | Select-Object -ExpandProperty Name
        if ($contracts) {
            $contracts_list = ($contracts | ForEach-Object { "  - $_" }) -join "`n"
        }
    }

    # 記錄啟動時間戳（供 SubagentStop 檢查記憶更新）
    $ts_file = "$log_dir/subagent-start-$agent_id.timestamp"
    Get-Date -Format "o" | Set-Content $ts_file

    $contracts_display = if ($contracts_list) { $contracts_list } else { "  （目前無合約）" }

    $context = @"
## $agent_type Basic Memory 已就緒 (Agent ID: $agent_id)

你的記憶資料夾: ``$memory_kb/$agent_folder/``

### 現有筆記:
$notes_list

### 介面合約（共享，所有 agent 皆可讀）:
$contracts_display

> 合約筆記由 PM 建立在 ``contracts/`` 資料夾。如 PM 在任務描述中附了合約 permalink，請用 ``read_note(permalink)`` 讀取完整規格。

### 搜尋規則（必須遵守）

**精確搜尋**（避免跨 app 污染）：
```
search_notes("關鍵字", tags=["app:<app-id>"])
search_notes("關鍵字", tags=["agent:$agent_folder"])
```

**❌ 禁止**直接用 ``search_notes("關鍵字")`` 而不帶 tags，這會混入其他 app 的結果。
"@

    $output = @{
        continue = $true
        hookSpecificOutput = @{
            hookEventName = "SubagentStart"
            additionalContext = $context
        }
    }

    $output | ConvertTo-Json -Depth 10
    exit 0
}
catch {
    $error_output = @{
        continue = $true
        systemMessage = "SubagentStart Hook 執行錯誤：$_"
    }
    $error_output | ConvertTo-Json
    exit 0
}
