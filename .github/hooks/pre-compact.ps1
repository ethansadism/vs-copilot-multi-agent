# PreCompact Hook - 在對話上下文被壓縮前保存重要狀態
# v0.02: 改用 Basic Memory (memory-kb)，不再讀 JSON

param(
    [Parameter(ValueFromPipeline=$true)]
    $input_json
)

try {
    $input = $input_json | ConvertFrom-Json
    $memory_kb = ".github/memory-kb"
    $log_dir = ".github/logs"

    # 寫入流程日誌
    if (-not (Test-Path $log_dir)) {
        New-Item -ItemType Directory -Path $log_dir -Force | Out-Null
    }
    $log_entry = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [PreCompact] Context compaction triggered (reason: $($input.trigger))"
    Add-Content -Path "$log_dir/hook-flow.log" -Value $log_entry

    # 從 memory-kb/project/project-overview.md 讀取摘要
    $summary = ""
    $overview_file = "$memory_kb/project/project-overview.md"
    if (Test-Path $overview_file) {
        $content = Get-Content $overview_file -Raw
        # 提取 Observations 區塊中的關鍵資訊
        $observations = @()
        foreach ($line in (Get-Content $overview_file)) {
            if ($line -match '^- (\w+) :: (.+)$') {
                $observations += $line.Trim()
            }
        }
        $obs_text = ($observations | Select-Object -First 10) -join "`n"

        # 列出各 folder 的筆記數量
        $folders = @("project", "crawler", "database", "frontend")
        $note_counts = @()
        foreach ($f in $folders) {
            $count = 0
            if (Test-Path "$memory_kb/$f") {
                $count = (Get-ChildItem "$memory_kb/$f" -Filter "*.md" | Measure-Object).Count
            }
            $note_counts += "  - $f/: $count 筆記"
        }
        $counts_text = $note_counts -join "`n"

        $summary = @"
## 專案記憶摘要（PreCompact 自動注入）

### 專案狀態:
$obs_text

### 知識庫統計:
$counts_text

### 記憶位置: .github/memory-kb/
使用 ``search_notes("關鍵字")`` 搜尋記憶，使用 ``write_note`` 更新記憶。
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
