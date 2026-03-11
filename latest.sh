#!/bin/sh
#
# Fetches the latest release version of openclaw from GitHub and normalizes
# it to YYYY-MM-DD (matching /usr/bin/container-version).
# Returns non-zero if the API call fails or returns no tag.

LATEST=$(curl -sL "https://api.github.com/repos/openclaw/openclaw/releases/latest" \
         | jq -r '.tag_name' \
         | sed 's/^v//' \
         | tr -d '[:space:]')

if [ -z "$LATEST" ] || [ "$LATEST" = "null" ]; then
  echo "Failed to retrieve latest release version" >&2
  exit 1
fi

NORMALIZED=$(printf '%s\n' "$LATEST" | awk '
  match($0, /([0-9]{4})[-.]([0-9]{1,2})[-.]([0-9]{1,2})/, m) {
    printf "%04d-%02d-%02d\n", m[1], m[2], m[3]
    exit
  }
')

if [ -z "$NORMALIZED" ]; then
  echo "Failed to parse latest release version" >&2
  exit 1
fi

printf '%s\n' "$NORMALIZED"
