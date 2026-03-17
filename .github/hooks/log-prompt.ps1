# UserPromptSubmit Hook - 記錄用戶提交的提示
# 用於審計和會話恢復

param(
    [Parameter(ValueFromPipeline=$true)]
    $input_json
)

try {
    $input = $input_json | ConvertFrom-Json
    $prompt = $input.prompt
    $session_id = $input.sessionId
    $timestamp = $input.timestamp

    # === 流程日誌 ===
    $flow_log_dir = ".github/logs"
    if (-not (Test-Path $flow_log_dir)) { New-Item -ItemType Directory -Path $flow_log_dir -Force | Out-Null }
    $prompt_preview = if ($prompt.Length -gt 80) { $prompt.Substring(0, 80) + "..." } else { $prompt }
    Add-Content -Path "$flow_log_dir/hook-flow.log" -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [UserPrompt] $prompt_preview"

    # 記錄提示
    $log_file = ".github/logs/prompts-$(Get-Date -Format 'yyyy-MM-dd').log"
    $log_dir = Split-Path $log_file
    if (-not (Test-Path $log_dir)) {
        New-Item -ItemType Directory -Path $log_dir -Force | Out-Null
    }
    
    $log_entry = @{
        timestamp = $timestamp
        session_id = $session_id
        prompt = $prompt
    } | ConvertTo-Json
    
    Add-Content -Path $log_file -Value $log_entry
    
    $output = @{
        continue = $true
    }
    
    $output | ConvertTo-Json
    exit 0
}
catch {
    exit 1
}
