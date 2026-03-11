#!/bin/sh
# ╭──────────────────────────────────────────────────────────╮
# │ Nyx Calder Version Reporter                              │
# ╰──────────────────────────────────────────────────────────╯

cd /opt/openclaw || {
  echo "unknown"
  exit 0
}

RAW_VERSION=$(node openclaw.mjs --version 2>/dev/null)

# Extract the release stamp (YYYY.M.D or YYYY-M-D) and normalize to YYYY.MM.DD
NORMALIZED=$(printf '%s\n' "$RAW_VERSION" | awk '
  match($0, /([0-9]{4})[-.]([0-9]{1,2})[-.]([0-9]{1,2})/, m) {
    printf "%04d.%d.%d\n", m[1], m[2], m[3]
    exit
  }
')

if [ -n "$NORMALIZED" ]; then
  printf '%s\n' "$NORMALIZED"
else
  echo "unknown"
fi
