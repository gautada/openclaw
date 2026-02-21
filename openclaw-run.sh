#!/bin/sh
# ╭──────────────────────────────────────────────────────────╮
# │ OpenClaw s6 Service Runner                               │
# ╰──────────────────────────────────────────────────────────╯

set -e

# _UID=1001
USER=$(getent passwd 1001 | cut -d: -f1)
OPENCLAW_HOME="/home/${USER}"
export OPENCLAW_HOME


 #Ensure workspace directory exists

# mkdir -p "${OPENCLAW_HOME}"

# Symlink configuration from mounted volume (ConfigMap)
# ln -fsv /mnt/volumes/configuration/SOUL.md \
#         "${OPENCLAW_HOME}/SOUL.md"
# ln -fsv /mnt/volumes/configuration/config.yaml \
#        "${OPENCLAW_HOME}/config.yaml"
# 
# # Ensure correct ownership
# chown -R ${_UID}:${_UID} "${OPENCLAW_HOME}"

# Change to application directory
cd /opt/openclaw || echo "Unknown application directory"

exec tail -f /dev/null
# Start OpenClaw gateway as user nyx (uid 1001)
# exec s6-setuidgid "${USER}" node openclaw.mjs gateway \
#   --allow-unconfigured \
#   --bind lan \
#   --port 8080
