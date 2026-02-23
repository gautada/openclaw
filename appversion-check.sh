#!/bin/sh
#
# Health check: verifies the running OpenClaw version matches the latest
# release on GitHub. Calls /usr/bin/container-version for the running version
# and /usr/bin/container-latest for the latest release.
# Returns 0 if versions match, non-zero otherwise.

# Get the version of the running OpenClaw instance
CURRENT_VERSION=$(/usr/bin/container-version | tr -d '[:space:]')
if [ -z "$CURRENT_VERSION" ]; then
  echo "Failed to get running app version from /usr/bin/container-version"
  exit 1
fi

# Get the latest release version from GitHub
LATEST_VERSION=$(/usr/bin/container-latest)
if [ -z "$LATEST_VERSION" ]; then
  echo "Failed to get latest release version from /usr/bin/container-latest"
  exit 1
fi

echo "Current version: $CURRENT_VERSION"
echo "Latest version:  $LATEST_VERSION"

if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
  echo "Version check passed"
  exit 0
else
  echo "Version check failed: versions do not match"
  exit 1
fi
