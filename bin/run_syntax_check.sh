#!/bin/bash
# Esegue `bash -n` su tutti gli script shell del repo. Se installato, esegue anche shellcheck.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail=0
while IFS= read -r -d '' f; do
    if ! bash -n "$f"; then
        echo "✗ Syntax error: $f"
        fail=1
    fi
done < <(find "$ROOT" -name '*.sh' -not -path '*/archive/*' -print0)

if command -v shellcheck >/dev/null 2>&1; then
    echo "Running shellcheck..."
    find "$ROOT" -name '*.sh' -not -path '*/archive/*' -exec shellcheck -S warning {} +
else
    echo "ℹ shellcheck non installato (opzionale: sudo apt-get install -y shellcheck)"
fi

[ "$fail" -eq 0 ] && echo "✓ Syntax OK su tutti gli script" || echo "✗ Errori di sintassi rilevati"
exit "$fail"
