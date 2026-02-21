#!/bin/sh
# ╭──────────────────────────────────────────────────────────╮
# │ Nyx Calder Health Check                                  │
# ╰──────────────────────────────────────────────────────────╯

# Check if OpenClaw gateway is responding
curl -sf http://127.0.0.1:8080/health > /dev/null 2>&1
exit $?
