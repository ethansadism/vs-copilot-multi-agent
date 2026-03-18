# SubagentStop Hook - 當 Subagent 完成時保存其工作和記憶
# 記錄完成狀態、發現的問題和建議

param(
    [Parameter(ValueFromPipeline=$true)]
    $input_json
)

try {
    $input = $input_json | ConvertFrom-Json
    $agent_type = $input.agent_type
    $agent_id = $input.agent_id
    $session_id = $input.sessionId
    $memory_kb = ".github/memory-kb"
    $reports_dir = ".github/reports"
    $log_dir = ".github/logs"

    # === 流程日誌 ===
    if (-not (Test-Path $log_dir)) { New-Item -ItemType Directory -Path $log_dir -Force | Out-Null }
    Add-Content -Path "$log_dir/hook-flow.log" -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [SubagentStop] <<< $agent_type (ID: $agent_id) completed"
    
    # 確保報告目錄存在
    if (-not (Test-Path $reports_dir)) {
        New-Item -ItemType Directory -Path $reports_dir -Force | Out-Null
    }
    
    # 生成報告文件名
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $report_file = "$reports_dir/$agent_type-report-$timestamp.md"
    
    # 記錄完成事件
    $completion_log = @{
        timestamp = Get-Date -Format "o"
        agent_type = $agent_type
        agent_id = $agent_id
        session_id = $session_id
        status = "COMPLETED"
        report_file = $report_file
    }
    
    # 記錄到會話日誌
    $session_log = "$log_dir/session-$session_id.json"
    if (Test-Path $session_log) {
        $log = Get-Content $session_log | ConvertFrom-Json
        # 強制轉成陣列，避免單元素時 ConvertFrom-Json 解析為物件導致 += 行為異常
        $agents = @($log.completed_agents)
        $agents += $completion_log
        $log.completed_agents = $agents
        $log | ConvertTo-Json -Depth 10 | Set-Content $session_log
    } else {
        @{
            session_id = $session_id
            started_at = Get-Date -Format "o"
            completed_agents = @($completion_log)
        } | ConvertTo-Json | Set-Content $session_log
    }
    
    # === 記憶更新偵測 ===
    $folder_map = @{
        "Crawler Expert"    = "crawler"
        "Database Expert"   = "database"
        "Frontend Engineer" = "frontend"
    }
    $agent_folder = $folder_map[$agent_type]
    $memory_updated = $false
    $warning = ""

    # 讀取 SubagentStart 記錄的啟動時間戳
    $ts_file = "$log_dir/subagent-start-$agent_id.timestamp"
    $start_time = $null
    if (Test-Path $ts_file) {
        $start_time = [datetime](Get-Content $ts_file)
        Remove-Item $ts_file -Force
    } else {
        # 無時間戳則用 10 分鐘前作為基準
        $start_time = (Get-Date).AddMinutes(-10)
    }

    # 檢查 agent 的 memory-kb folder 是否有新增或修改的檔案
    if ($agent_folder -and (Test-Path "$memory_kb/$agent_folder")) {
        $modified_notes = Get-ChildItem "$memory_kb/$agent_folder" -Filter "*.md" | Where-Object { $_.LastWriteTime -gt $start_time }
        if ($modified_notes) {
            $memory_updated = $true
            $updated_list = ($modified_notes | Select-Object -ExpandProperty Name) -join ", "
        }
    }

    if (-not $memory_updated) {
        $warning = @"

### ⚠️ 記憶未更新警告
$agent_type 在本次任務中**未更新記憶筆記**（$memory_kb/$agent_folder/ 無新增或修改）。
請立即用 ``write_note`` 記錄：
- 完成了什麼任務
- 遇到的問題和解決方案
- 可複用的經驗

**未更新記憶 = 任務未完成。**
"@
    } else {
        $warning = "`n已偵測到記憶更新: $updated_list"
    }

    # 返回完成確認 + 記憶偵測結果
    $output = @{
        continue = $true
        hookSpecificOutput = @{
            hookEventName = "SubagentStop"
            additionalContext = "$agent_type 已完成任務。報告位置: $report_file$warning"
        }
    }
    
    $output | ConvertTo-Json -Depth 10
    exit 0
}
catch {
    # 非阻塞錯誤 - 允許 Agent 繼續
    @{ continue = $true; systemMessage = "SubagentStop Hook 錯誤：$_" } | ConvertTo-Json
    exit 0
}
