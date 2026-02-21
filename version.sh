#!/bin/sh
# ╭──────────────────────────────────────────────────────────╮
# │ Nyx Calder Version Reporter                              │
# ╰──────────────────────────────────────────────────────────╯

cd /opt/openclaw || exit
node openclaw.mjs --version 2>/dev/null || echo "unknown"
