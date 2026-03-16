# PostToolUse Hook - 在 Tool 執行後記錄進度
# 用於審計和記憶更新

param(
    [Parameter(ValueFromPipeline=$true)]
    $input_json
)

try {
    $input = $input_json | ConvertFrom-Json
    $tool_name = $input.tool_name
    $tool_input = $input.tool_input
    $tool_response = $input.tool_response
    $timestamp = $input.timestamp
    
    # 記錄 Tool 使用情況
    $log_file = ".github/logs/tool-usage-$(Get-Date -Format 'yyyy-MM-dd').log"
    $log_dir = Split-Path $log_file
    if (-not (Test-Path $log_dir)) {
        New-Item -ItemType Directory -Path $log_dir -Force | Out-Null
    }
    
    $log_entry = @{
        timestamp = $timestamp
        tool_name = $tool_name
        tool_input = $tool_input
        response_length = $tool_response.Length
        status = "SUCCESS"
    } | ConvertTo-Json
    
    Add-Content -Path $log_file -Value $log_entry
    
    # 返回確認（不阻止 Agent 繼續）
    $output = @{
        continue = $true
    }
    
    $output | ConvertTo-Json
    exit 0
}
catch {
    # 非阻塞錯誤
    exit 1
}
