#!/bin/sh
# ╭──────────────────────────────────────────────────────────╮
# │ Nyx Calder Version Reporter                              │
# ╰──────────────────────────────────────────────────────────╯

# Get RAW_VERSION from the app
cd /opt/openclaw || {
  echo "unknown"
  exit 0
}

# Capture version and strip any ANSI codes
# The runtime reports versions like "OpenClaw2026.3.8(3caab92)"
RAW_VERSION=$(node openclaw.mjs --version 2>/dev/null | sed 's/\x1B\[[0-9;]*[mK]//g')

# Extract version string matching YYYY.M.D or YYYY.MM.DD
# e.g. "OpenClaw2026.3.8(3caab92)" -> "2026.3.8"
VERSION=$(echo "$RAW_VERSION" | grep -oE '[0-9]{4}\.[0-9]{1,2}\.[0-9]{1,2}' | head -n1)

if [ -n "$VERSION" ]; then
  echo "$VERSION"
else
  echo "unknown"
fi
