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
        $log.completed_agents += $completion_log
        $log | ConvertTo-Json | Set-Content $session_log
    } else {
        @{
            session_id = $session_id
            started_at = Get-Date -Format "o"
            completed_agents = @($completion_log)
        } | ConvertTo-Json | Set-Content $session_log
    }
    
    # 返回完成確認，提醒用 write_note 更新記憶
    $output = @{
        continue = $true
        hookSpecificOutput = @{
            hookEventName = "SubagentStop"
            additionalContext = "$agent_type 已完成任務。請確認已用 write_note 更新記憶筆記，報告位置: $report_file"
        }
    }
    
    $output | ConvertTo-Json -Depth 10
    exit 0
}
catch {
    # 非阻塞錯誤 - 允許 Agent 繼續
    exit 1
}
