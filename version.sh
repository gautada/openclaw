#!/bin/sh
# ╭──────────────────────────────────────────────────────────╮
# │ Nyx Calder Version Reporter                              │
# ╰──────────────────────────────────────────────────────────╯
set -eux
cd /opt/openclaw || {
  echo "unknown"
  exit 0
}

RAW_VERSION=$(node openclaw.mjs --version 2>/dev/null)
echo "RAW==$RAW_VERSION"
# Extract the release stamp (YYYY.M.D style) and normalize to YYYY.MM.DD.
# Tolerates arbitrary separators and strips ANSI color codes if present.
NORMALIZED=$(printf '%s\n' "$RAW_VERSION" | awk '
  {
    gsub(/\033\[[0-9;]*[A-Za-z]/, "")
    if (match($0, /([0-9]{4})[^0-9]*([0-9]{1,2})[^0-9]*([0-9]{1,2})/, m)) {
      printf "%04d.%d.%d\n", m[1], m[2], m[3]
      exit
    }
  }
')

if [ -n "$NORMALIZED" ]; then
  printf '%s\n' "$NORMALIZED"
else
  echo "unknown"
fi
set +eux
