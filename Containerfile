ARG CONTAINER_VERSION=latest

# ══════════════════════════════════════════════════════════════
# Stage 1: Build
# ══════════════════════════════════════════════════════════════
FROM docker.io/gautada/debian:${CONTAINER_VERSION} AS builder

# ╭──────────────────────────────────────────────────────────╮
# │ Build Dependencies                                       │
# ╰──────────────────────────────────────────────────────────╯
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates curl git jq unzip \
 && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
 && apt-get install -y --no-install-recommends nodejs \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

COPY latest.sh /usr/bin/container-latest
RUN chmod +x /usr/bin/container-latest

WORKDIR /build

ENV CI=true

# Clone OpenClaw at the latest release tag and build
RUN OPENCLAW_VERSION=$(/usr/bin/container-latest) \
 && { [ -n "$OPENCLAW_VERSION" ] && [ "$OPENCLAW_VERSION" != "null" ] \
      || { echo "ERROR: failed to resolve latest OpenClaw version" >&2; exit 1; }; } \
 && echo "Building OpenClaw ${OPENCLAW_VERSION}" \
 && git config --global advice.detachedHead false \
 && git clone --depth 1 --branch "v${OPENCLAW_VERSION}" \
         https://github.com/openclaw/openclaw.git . \
 && corepack enable \
 && pnpm install --frozen-lockfile \
 && pnpm build \
 && pnpm ui:build \
 && pnpm prune --prod

# ══════════════════════════════════════════════════════════════
# Stage 2: Runtime
# ══════════════════════════════════════════════════════════════
FROM docker.io/gautada/debian:${CONTAINER_VERSION} AS container

# ╭──────────────────────────────────────────────────────────╮
# │ Metadata                                                 │
# ╰──────────────────────────────────────────────────────────╯
LABEL org.opencontainers.image.title="openclaw"
LABEL org.opencontainers.image.description="Open Claw - Autonomous Agent Platform"
LABEL org.opencontainers.image.url="https://github.com/gautada/openclaw"
LABEL org.opencontainers.image.source="https://github.com/gautada/openclaw"
LABEL org.opencontainers.image.documentation="https://github.com/gautada/openclaw/blob/main/README.md"

# ╭──────────────────────────────────────────────────────────╮
# │ Runtime Dependencies                                     │
# ╰──────────────────────────────────────────────────────────╯
# Node.js, Chromium, and Otel-Collector — no build tools in the runtime stage
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates curl jq \
 && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
 && apt-get install -y --no-install-recommends nodejs chromium \
    fonts-liberation fontconfig libasound2t64 libatk-bridge2.0-0t64 \
    libatspi2.0-0t64 libcairo2 libdbus-1-3 libdrm2 libgbm1 libglib2.0-0t64 \
    libgtk-3-0t64 libnspr4 libnss3 libpango-1.0-0 libxcomposite1 \
    libxdamage1 libxfixes3 libxkbcommon0 libxrandr2 libxss1 \
 && curl -L https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v0.121.0/otelcol-contrib_0.121.0_linux_arm64.tar.gz | tar xz -C /usr/bin otelcol-contrib \
 && mv /usr/bin/otelcol-contrib /usr/bin/otel-collector-contrib \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# ╭──────────────────────────────────────────────────────────╮
# │ Application                                              │
# ╰──────────────────────────────────────────────────────────╯
WORKDIR /opt/openclaw

# Copy production artifacts only from the builder stage
COPY --from=builder /build/dist         ./dist
COPY --from=builder /build/node_modules ./node_modules
COPY --from=builder /build/openclaw.mjs ./openclaw.mjs
COPY --from=builder /build/package.json ./package.json
COPY --from=builder /build/packages     ./packages

# ╭──────────────────────────────────────────────────────────╮
# │ User                                                     │
# ╰──────────────────────────────────────────────────────────╯
ARG USER=cheliped
RUN /usr/sbin/usermod -l $USER debian \
 && /usr/sbin/usermod -d /home/$USER -m $USER \
 && /usr/sbin/groupmod -n $USER debian \
 && /bin/passwd -d $USER \
 && rm -rf /home/debian \
 && chown -R $USER:$USER /opt/openclaw

ENV OPENCLAW_HOME=/home/$USER
ENV NODE_ENV=production

# ╭──────────────────────────────────────────────────────────╮
# │ Service                                                  │
# ╰──────────────────────────────────────────────────────────╯
RUN mkdir -p /etc/services.d/openclaw /etc/services.d/otel-collector
COPY openclaw-run.sh /etc/services.d/openclaw/run
COPY services/otel-collector/run /etc/services.d/otel-collector/run
COPY services/otel-collector/otel-collector.yaml /opt/openclaw/otel-collector.yaml
# Default openclaw.json (overridable via volume mount)
COPY openclaw.json /home/$USER/.openclaw/openclaw.json
RUN chmod +x /etc/services.d/openclaw/run /etc/services.d/otel-collector/run && chown -R $USER:$USER /home/$USER

EXPOSE 8080/tcp 8889/tcp
WORKDIR /opt/openclaw
