#!/bin/sh
#
# Fetches the latest release version of openclaw from GitHub.
# Strips the leading 'v' prefix and any whitespace, then prints
# the clean version string to stdout.
# Returns non-zero if the API call fails or returns no tag.

LATEST=$(curl -sL "https://api.github.com/repos/openclaw/openclaw/releases/latest" \
         | jq -r '.tag_name' \
         | sed 's/^v//' \
         | tr -d '[:space:]')

if [ -z "$LATEST" ] || [ "$LATEST" = "null" ]; then
  echo "Failed to retrieve latest release version" >&2
  exit 1
fi

printf '%s\n' "$LATEST"
