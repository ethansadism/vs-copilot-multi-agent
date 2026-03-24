#!/bin/bash
# 共享 Python 偵測（所有 hook 用 source 載入）
# 用法：source "$(dirname "$0")/detect-python.sh"
# 結果：$PYTHON 設為可用的 Python 指令

if [ -n "$PYTHON" ]; then
    return 0 2>/dev/null || exit 0
fi

for cmd in python3 python py; do
    if "$cmd" --version >/dev/null 2>&1; then
        export PYTHON="$cmd"
        return 0 2>/dev/null || exit 0
    fi
done

echo '{"error": "Python not found"}' >&2
export PYTHON="python3"  # fallback, will fail with clear error
