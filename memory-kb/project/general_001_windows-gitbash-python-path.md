---
title: general_001_windows-gitbash-python-path
type: note
permalink: multi-agent-system/project/general-001-windows-gitbash-python-path
tags:
- app:general
- agent:claude
- experience
- bug
---

# Windows Git Bash + Python 路徑不相容

## 問題

在 Windows Git Bash 環境中，shell 腳本呼叫 Windows 原生 Python (`py`) 時，Python **無法解析 MINGW 虛擬路徑**。

```
# Bash 看得到：
test -f /tmp/tmp.M8N2j8Bdg0/framework/.claude/settings.json  → OK

# Python 看不到：
os.path.exists("/tmp/tmp.M8N2j8Bdg0/framework/.claude/settings.json")  → False
```

## 根因

- Git Bash 的 `/tmp` 是 MINGW 虛擬路徑，映射到 `C:\Users\{user}\AppData\Local\Temp`
- `mktemp -d` 回傳 `/tmp/tmp.xxx`（MINGW 格式）
- Windows 原生 Python (`py`, `python`) 不認識這個路徑
- `set -e` 下 Python FileNotFoundError 導致腳本靜默退出，極難 debug

## 同場加映：Windows Python 指令問題

- `python3` / `python` 可能是 Microsoft Store 的 stub（exit code 49），不是真正的 Python
- 真正可用的是 `py`（Python Launcher for Windows）
- 偵測順序應為：`python3` → `python` → `py`，用 `"$cmd" --version >/dev/null 2>&1` 檢查

## 解法

```bash
# 1. 偵測 Python
for cmd in python3 python py; do
    if "$cmd" --version >/dev/null 2>&1; then PYTHON="$cmd"; break; fi
done

# 2. 路徑轉換（cygpath 只在 MINGW/Cygwin 存在）
if command -v cygpath >/dev/null 2>&1; then
    SRC_PY="$(cygpath -w "$SRC")"      # /tmp/xxx → C:\Users\...\Temp\xxx
    CWD_PY="$(cygpath -w "$(pwd)")"
else
    SRC_PY="$SRC"                       # macOS/Linux 不需轉換
    CWD_PY="$(pwd)"
fi

# 3. Python heredoc 中使用轉換後的路徑
$PYTHON - <<PYEOF
import os
os.chdir(r"$CWD_PY")
with open(os.path.join(r"$SRC_PY", ".claude", "settings.json")) as f:
    ...
PYEOF
```

## 防範清單

寫 shell 腳本要在 Windows Git Bash 跑時，檢查：
- [ ] `python3` 是否存在？用偵測迴圈
- [ ] 有傳路徑給 Python 嗎？用 `cygpath -w` 轉換
- [ ] `set -e` 下錯誤會靜默退出——加 `echo` 在關鍵步驟前後
- [ ] `/tmp`、`mktemp -d` 的路徑是 MINGW 格式——bash 工具能用，Python/Node 等原生工具不能
- [ ] `curl -o /tmp/file` 可能也會失敗（error 23）

## Observations

- app :: general
- agent :: claude
- type :: experience
- bug_date :: 2026-03-23 17:30
- resolved :: true
- impact :: bootstrap.sh 在 Windows 完全無法執行，靜默失敗無錯誤訊息
