#!/bin/sh
# ╭──────────────────────────────────────────────────────────╮
# │ Nyx Calder Health Check                                  │
# ╰──────────────────────────────────────────────────────────╯

HEALTH_URL="http://127.0.0.1:8080/health"
RESPONSE_FILE="/tmp/openclaw_health_response"
STDERR_FILE="/tmp/openclaw_health_stderr"

# Probe the OpenClaw health endpoint.
# -s  : silent (suppress progress meter)
# -o  : write response body to file (keep stdout clean for -w)
# -w  : write HTTP status code to stdout after transfer
# Retry parameters match original: up to 60 s (12 × 5 s) for transient errors.
HTTP_CODE=$(curl -s \
  --retry 12 \
  --retry-delay 5 \
  --retry-all-errors \
  -o "$RESPONSE_FILE" \
  -w '%{http_code}' \
  "$HEALTH_URL" 2>"$STDERR_FILE")
CURL_EXIT=$?

# Success path: curl exited cleanly and server returned HTTP 2xx.
if [ "$CURL_EXIT" -eq 0 ] && [ "${HTTP_CODE:-0}" -ge 200 ] && [ "${HTTP_CODE:-0}" -lt 300 ]; then
  rm -f "$RESPONSE_FILE" "$STDERR_FILE"
  exit 0
fi

# Failure path: print structured diagnostics then exit non-zero.
printf '\n=== openclaw-running HEALTH CHECK FAILED ===\n'
printf 'Timestamp : %s\n' "$(date)"
printf 'HTTP Code : %s\n' "${HTTP_CODE:-unknown}"
printf 'Curl Exit : %s\n' "$CURL_EXIT"

printf '\n--- Response Body ---\n'
if [ -s "$RESPONSE_FILE" ]; then
  cat "$RESPONSE_FILE"
else
  printf '(empty)\n'
fi

printf '\n--- Curl Stderr ---\n'
if [ -s "$STDERR_FILE" ]; then
  cat "$STDERR_FILE"
else
  printf '(none)\n'
fi

printf '\n--- Processes (node / pnpm / openclaw) ---\n'
# shellcheck disable=SC2009
PROCS=$(ps aux | grep -E 'openclaw|node|pnpm' | grep -v grep)
if [ -n "$PROCS" ]; then
  printf '%s\n' "$PROCS"
else
  printf '(none found)\n'
fi

printf '\n--- Port :8080 Binding ---\n'
PORTS=$(ss -tlnp 2>/dev/null | grep ':8080')
if [ -n "$PORTS" ]; then
  printf '%s\n' "$PORTS"
else
  printf 'port 8080 not bound\n'
fi

printf '\n--- s6 Service State (/etc/services.d/openclaw) ---\n'
s6-svstat /etc/services.d/openclaw 2>/dev/null || printf 's6-svstat unavailable\n'

printf '\n--- s6 Service Log (last 50 lines) ---\n'
LOG_FOUND=0
for LOG_PATH in \
  /run/s6/legacy-services/openclaw/log/current \
  /run/s6/legacyservices/openclaw/log/current \
  /var/log/s6/openclaw/current \
  /etc/services.d/openclaw/log/current; do
  if [ -f "$LOG_PATH" ]; then
    printf 'Path: %s\n' "$LOG_PATH"
    tail -50 "$LOG_PATH"
    LOG_FOUND=1
    break
  fi
done
if [ "$LOG_FOUND" -eq 0 ]; then
  printf 'no s6 log file found at known paths\n'
fi

printf '\n============================================\n'

rm -f "$RESPONSE_FILE" "$STDERR_FILE"
exit 1
