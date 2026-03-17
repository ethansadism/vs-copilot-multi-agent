# SubagentStart Hook - 當 Subagent 啟動時加載其記憶
# 根據 Agent 類型加載相應的記憶

param(
    [Parameter(ValueFromPipeline=$true)]
    $input_json
)

try {
    $input = $input_json | ConvertFrom-Json
    $agent_type = $input.agent_type
    $agent_id = $input.agent_id
    $memory_dir = ".github/memory"
    $log_dir = ".github/logs"

    # === 流程日誌 ===
    if (-not (Test-Path $log_dir)) { New-Item -ItemType Directory -Path $log_dir -Force | Out-Null }
    Add-Content -Path "$log_dir/hook-flow.log" -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [SubagentStart] >>> $agent_type (ID: $agent_id) spawned"
    
    $memory_map = @{
        "Crawler Expert" = "crawler-memory.json"
        "Database Expert" = "database-memory.json"
        "Frontend Engineer" = "frontend-memory.json"
    }
    
    $memory_file = $memory_map[$agent_type]
    
    if ($memory_file -and (Test-Path "$memory_dir/$memory_file")) {
        $agent_memory = Get-Content "$memory_dir/$memory_file" | ConvertFrom-Json
        
        $context = @"
## $agent_type 的記憶已加載 (Agent ID: $agent_id)

**上次更新**: $($agent_memory.last_update)

### 已解決的問題:
$($agent_memory.solved_problems | ConvertTo-Json -Depth 2)

### 最佳實踐:
$($agent_memory.best_practices -join "`n- ")

### 工具和庫:
$($agent_memory.tools_and_libraries -join ", ")

---
**重要**: 在執行任務前，請檢查已解決問題列表，避免重複犯同樣的錯誤。
"@
        
        $output = @{
            continue = $true
            hookSpecificOutput = @{
                hookEventName = "SubagentStart"
                additionalContext = $context
            }
        }
    } else {
        $output = @{
            continue = $true
            systemMessage = "未找到 $agent_type 的記憶文件"
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
