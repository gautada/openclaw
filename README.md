# OpenClaw Container

A container image packaging the [OpenClaw](https://github.com/openclaw/openclaw)
autonomous agent platform, built on [`gautada/debian`](https://github.com/gautada/debian).
Runs the OpenClaw gateway as an s6-supervised service, enabling autonomous AI
agent workflows via chat channels, GitHub integrations, and cron-based automation.

## Purpose

This container provides a ready-to-run OpenClaw gateway with:

- **Autonomous agent runtime** - Runs the OpenClaw gateway and agent loop
- **Browser support** - Chromium pre-installed for browser-based agent tools
- **Health monitoring** - Built-in health and application version checks
- **Persistent workspace** - Agent workspace, config, and session data via volumes

## Features

### OpenClaw Gateway

The gateway is managed as an s6 service (`/etc/services.d/openclaw`), started
via `openclaw-run.sh`. It runs the OpenClaw gateway process under the `cheliped`
user (UID 1001) on port `8080`.

```bash
# The gateway starts automatically on container start
# Check health from inside the container:
container-test
```

### Health Monitoring

The container ships a built-in health check:

- **`openclaw-running`** — polls `http://127.0.0.1:8080/health` with retry logic
  (up to 60s). On failure, emits structured diagnostics: HTTP status, response
  body, process list, port binding, s6 service state, and log tail.

Standard health endpoints are available via symlinks from `gautada/debian`:

```
/usr/bin/container-liveness   # liveness probe
/usr/bin/container-readiness  # readiness probe
/usr/bin/container-startup    # startup probe
/usr/bin/container-test       # CI/CD test
```

### Application Version

The `version.sh` script returns the running OpenClaw version via
`/usr/bin/container-version`. Used by CI/CD to verify the built image
matches the intended release.

### Latest Version Check

The `latest.sh` script (`/usr/bin/container-latest`) queries the GitHub API
to retrieve the latest published release version of OpenClaw. Used by
`appversion-check.sh` to detect version drift.

### Application Version Check

`appversion-check.sh` is installed at `/etc/container/health.d/appversion-check`.
It compares the running container version (`container-version`) against the
latest published release (`container-latest`) and fails the health check if
they diverge.

### Browser Support

[Chromium](https://www.chromium.org) is pre-installed for use with the
OpenClaw browser tool. Runs headless with `--no-sandbox` in the container
environment.

## User Configuration

| Setting  | Value        |
| -------- | ------------ |
| Username | `cheliped`   |
| UID      | `1001`       |
| Shell    | `/bin/zsh`   |
| Home     | `/home/cheliped` |

> The user is named after the large crusher claw of a lobster — the *cheliped*
> (from *chela*, the claw). It is the container's namesake and the OpenClaw
> workspace owner.

## Configuration

Agent configuration is provided via `openclaw.json`, copied into the container
at `/home/cheliped/.openclaw/openclaw.json`. Mount a custom config at runtime
to override:

```bash
podman run -d \
  -v ./openclaw.json:/home/cheliped/.openclaw/openclaw.json:ro \
  gautada/openclaw
```

## Build

### Prerequisites

- Podman or Docker
- Git (for cloning)

### Build Commands

```bash
# Standard build
podman build -t openclaw .

# Build without cache
podman build --no-cache -t openclaw .

# Build specific OpenClaw version
podman build --build-arg OPENCLAW_VERSION=2026.2.22 -t openclaw .
```

### Build Arguments

| Argument             | Default  | Description                          |
| -------------------- | -------- | ------------------------------------ |
| `CONTAINER_VERSION`  | `13.3`   | Debian base image version            |
| `OPENCLAW_VERSION`   | `main`   | OpenClaw release version to build    |
| `USER`               | `cheliped` | Container user name                |

## Run

```bash
# Run the container
podman run -d --name openclaw -p 8080:8080 gautada/openclaw

# Run with persistent workspace
podman run -d --name openclaw \
  -p 8080:8080 \
  -v ./workspace:/home/cheliped/.openclaw/workspace \
  -v ./openclaw.json:/home/cheliped/.openclaw/openclaw.json:ro \
  gautada/openclaw

# Run health check
podman exec openclaw container-test

# Open an interactive shell
podman exec -it --user cheliped openclaw /bin/zsh
```

## Project Structure

```
.
├── .args                    # Build arguments
├── .gitignore               # Git ignore rules
├── .hadolint.yaml           # Hadolint Dockerfile linter configuration
├── .pre-commit-config.yaml  # Pre-commit hook configuration
├── .shellcheckrc            # ShellCheck configuration
├── Containerfile            # Container build definition
├── README.md                # This file
├── appversion-check.sh      # Health check: compares running vs latest version
├── latest.sh                # Queries GitHub API for latest OpenClaw release
├── openclaw-run.sh          # s6 service runner for the OpenClaw gateway
├── openclaw-running.sh      # Health check: verifies gateway is responding
├── openclaw.json            # Default OpenClaw configuration
└── version.sh               # Returns the running OpenClaw version
```

## License

[MIT](https://github.com/openclaw/openclaw/blob/main/LICENSE)

## Links

- [OpenClaw](https://github.com/openclaw/openclaw)
- [Docker Hub](https://hub.docker.com/r/gautada/openclaw)
- [GitHub](https://github.com/gautada/openclaw)
- [Docs](https://docs.openclaw.ai)
