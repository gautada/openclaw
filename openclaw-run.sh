#!/bin/sh
# ╭──────────────────────────────────────────────────────────╮
# │ OpenClaw s6 Service Runner                               │
# ╰──────────────────────────────────────────────────────────╯

set -e

# The application user is created with UID 1001
USER=$(getent passwd 1001 | cut -d: -f1)
OPENCLAW_HOME="/home/${USER}"
export OPENCLAW_HOME

# Change to application directory
cd /opt/openclaw || exit 1

# Start OpenClaw gateway via s6-setuidgid
exec s6-setuidgid "${USER}" node openclaw.mjs gateway run
