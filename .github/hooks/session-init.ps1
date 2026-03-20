# SessionStart Hook - 初始化會話並加載記憶
# 這個腳本在 Agent 會話開始時運行

param(
    [Parameter(ValueFromPipeline=$true)]
    $input_json
)

try {
    $input = $input_json | ConvertFrom-Json
    $session_id = $input.sessionId
    $memory_kb = "memory-kb"
    $log_dir = ".github/logs"

    # === 流程日誌 ===
    if (-not (Test-Path $log_dir)) { New-Item -ItemType Directory -Path $log_dir -Force | Out-Null }
    Add-Content -Path "$log_dir/hook-flow.log" -Value "`n========================================"
    Add-Content -Path "$log_dir/hook-flow.log" -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [SessionStart] New session: $session_id"
    
    # 檢查 memory-kb 是否存在
    $overview_file = "$memory_kb/project/project-overview.md"
    if (Test-Path $overview_file) {
        $overview_content = Get-Content $overview_file -Raw
        
        Add-Content -Path "$log_dir/hook-flow.log" -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [SessionStart] Memory KB loaded from $memory_kb"

        # 返回包含記憶提示的上下文
        $output = @{
            continue = $true
            hookSpecificOutput = @{
                hookEventName = "SessionStart"
                additionalContext = @"
## Basic Memory 已就緒 (Session: $session_id)

記憶知識庫位於 `$memory_kb/`，請使用 MCP 工具操作：
- ``search_notes("project overview")`` 查詢專案狀態
- ``search_notes("known issues")`` 查詢已知問題
- ``search_notes("關鍵字")`` 搜尋相關經驗

### 資料夾結構
- ``project/`` — 專案總覽與已知問題
- ``crawler/`` — 爬蟲經驗與最佳實踐
- ``database/`` — 資料模型與 SQLite 模式
- ``frontend/`` — 設計系統與組件庫

**請先用 search_notes 查詢記憶再開始工作。**
"@
            }
        }
    } else {
        $output = @{
            continue = $true
            systemMessage = "警告：找不到記憶知識庫 ($memory_kb)，請確認 Basic Memory 已設定"
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
