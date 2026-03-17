# SessionStart Hook - 初始化會話並加載記憶
# 這個腳本在 Agent 會話開始時運行

param(
    [Parameter(ValueFromPipeline=$true)]
    $input_json
)

try {
    $input = $input_json | ConvertFrom-Json
    $session_id = $input.sessionId
    $memory_dir = ".github/memory"
    $log_dir = ".github/logs"

    # === 流程日誌 ===
    if (-not (Test-Path $log_dir)) { New-Item -ItemType Directory -Path $log_dir -Force | Out-Null }
    Add-Content -Path "$log_dir/hook-flow.log" -Value "`n========================================"
    Add-Content -Path "$log_dir/hook-flow.log" -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [SessionStart] New session: $session_id"
    
    # 讀取項目狀態
    if (Test-Path "$memory_dir/project-state.json") {
        $project_state = Get-Content "$memory_dir/project-state.json" | ConvertFrom-Json
        $context = @{
            project_name = $project_state.project_name
            last_update = $project_state.last_update
            active_tasks = $project_state.active_tasks
            known_issues = $project_state.known_issues
            session_id = $session_id
        }
        
        Add-Content -Path "$log_dir/hook-flow.log" -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [SessionStart] Memory loaded: $($project_state.project_name) | Phase: $($project_state.current_phase) | Known issues: $($project_state.known_issues.Count)"

        # 返回包含記憶的上下文
        $output = @{
            continue = $true
            hookSpecificOutput = @{
                hookEventName = "SessionStart"
                additionalContext = @"
## 專案記憶已加載 (Session: $session_id)

**項目**: $($project_state.project_name)
**當前階段**: $($project_state.current_phase)
**最後更新**: $($project_state.last_update)

### 已知問題與解決方案:
$($project_state.known_issues | ConvertTo-Json -Depth 2)

### 活躍任務:
$($project_state.active_tasks | ConvertTo-Json -Depth 2)

記憶系統已激活，所有 Agent 可以查閱其專業領域的記憶。
"@
            }
        }
    } else {
        $output = @{
            continue = $true
            systemMessage = "警告：找不到項目狀態記憶文件"
        }
    }
    
    $output | ConvertTo-Json -Depth 10
    exit 0
}
catch {
    $error_output = @{
        continue = $true
        systemMessage = "Hook 執行錯誤：$_"
    }
    $error_output | ConvertTo-Json
    exit 0
}
