#!/bin/sh
# ╭──────────────────────────────────────────────────────────╮
# │ Nyx Calder Health Check                                  │
# ╰──────────────────────────────────────────────────────────╯

# Check if OpenClaw gateway is responding (retry up to 60s)
curl -sf --retry 12 --retry-delay 5 --retry-all-errors \
     http://127.0.0.1:8080/health > /dev/null 2>&1
exit $?
