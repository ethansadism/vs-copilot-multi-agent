# PreCompact Hook - 在對話上下文被壓縮前保存重要狀態
# 確保關鍵記憶不會在 compact 中丟失

param(
    [Parameter(ValueFromPipeline=$true)]
    $input_json
)

try {
    $input = $input_json | ConvertFrom-Json
    $memory_dir = ".github/memory"
    $log_dir = ".github/logs"

    # 寫入流程日誌
    if (-not (Test-Path $log_dir)) {
        New-Item -ItemType Directory -Path $log_dir -Force | Out-Null
    }
    $log_entry = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [PreCompact] Context compaction triggered (reason: $($input.trigger))"
    Add-Content -Path "$log_dir/hook-flow.log" -Value $log_entry

    # 讀取當前專案狀態摘要，注入到 compact 後的上下文中
    $summary = ""
    if (Test-Path "$memory_dir/project-state.json") {
        $state = Get-Content "$memory_dir/project-state.json" | ConvertFrom-Json
        $summary = @"
## 專案記憶摘要（PreCompact 自動注入）
- 專案: $($state.project_name)
- 階段: $($state.current_phase)
- 記憶位置: .github/memory/
- 已知問題數: $($state.known_issues.Count)
- 請在需要時重新讀取記憶檔案
"@
    }

    $output = @{ continue = $true }
    if ($summary) {
        $output.hookSpecificOutput = @{
            hookEventName = "PreCompact"
            additionalContext = $summary
        }
    }

    $output | ConvertTo-Json -Depth 10
    exit 0
}
catch {
    @{ continue = $true } | ConvertTo-Json
    exit 0
}
