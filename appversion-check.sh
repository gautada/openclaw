#!/bin/sh
#
# Health check: verifies the running OpenClaw version matches the
# latest release on GitHub. Both values are expected to be normalized to
# YYYY.MM.DD (see /usr/bin/container-version and /usr/bin/container-latest).

normalize() {
  printf '%s' "$1" | tr -d '[:space:]'
}

CURRENT_VERSION=$(normalize "$(/usr/bin/container-version 2>/dev/null)")
if [ -z "$CURRENT_VERSION" ] || [ "$CURRENT_VERSION" = "unknown" ]; then
  echo "Failed to get running app version from /usr/bin/container-version"
  exit 1
fi

LATEST_VERSION=$(normalize "$(/usr/bin/container-latest --minimum 2>/dev/null)")
if [ -z "$LATEST_VERSION" ] || [ "$LATEST_VERSION" = "unknown" ]; then
  echo "Failed to get latest release version from /usr/bin/container-latest"
  exit 1
fi

echo "Current version: $CURRENT_VERSION"
echo "Latest version:  $LATEST_VERSION"

# Pass if CURRENT_VERSION contains LATEST_VERSION anywhere in the string.
# The runtime now reports versions like "OpenClaw2026.3.8(3caab92)" so we
# match on substring instead of prefix to accommodate the leading product
# name and trailing commit signature.
case "$CURRENT_VERSION" in
  *"${LATEST_VERSION}"*)
    echo "Version check passed"
    exit 0
    ;;
  *)
    echo "Version check failed: $CURRENT_VERSION does not contain $LATEST_VERSION"
    exit 1
    ;;
esac
