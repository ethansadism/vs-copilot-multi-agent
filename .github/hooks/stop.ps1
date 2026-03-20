# Stop Hook - 會話結束前檢查記憶是否已更新
# 如果 memory-kb 中的筆記在本次會話中未被修改，注入提醒

param(
    [Parameter(ValueFromPipeline=$true)]
    $input_json
)

try {
    $input = $input_json | ConvertFrom-Json
    $overview_file = "memory-kb/project/project-overview.md"
    $log_dir = ".github/logs"

    # 寫入流程日誌
    if (-not (Test-Path $log_dir)) {
        New-Item -ItemType Directory -Path $log_dir -Force | Out-Null
    }
    $log_entry = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [Stop] Session ending"
    Add-Content -Path "$log_dir/hook-flow.log" -Value $log_entry

    if (Test-Path $overview_file) {
        $mtime = (Get-Item $overview_file).LastWriteTime
        $age_minutes = ((Get-Date) - $mtime).TotalMinutes

        if ($age_minutes -gt 10) {
            $output = @{
                continue = $true
                hookSpecificOutput = @{
                    hookEventName = "Stop"
                    additionalContext = @"
## 記憶更新提醒
project-overview.md 在本次會話中似乎未被更新（上次修改: $($mtime.ToString('yyyy-MM-dd HH:mm'))）。
請在結束前用 ``write_note`` 更新記憶：
- 記錄本次完成的任務
- 記錄新發現的問題和解決方案（更新 known-issues.md）
- 更新系統狀態
"@
                }
            }
        } else {
            $output = @{ continue = $true }
        }
    } else {
        $output = @{
            continue = $true
            systemMessage = "警告：找不到 project-overview.md，請確認 Basic Memory 知識庫已建立"
        }
    }

    $output | ConvertTo-Json -Depth 10
    exit 0
}
catch {
    @{ continue = $true } | ConvertTo-Json
    exit 0
}
