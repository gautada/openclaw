# ╭──────────────────────────────────────────────────────────╮
# │ Nyx Calder - OpenClaw AI Assistant Container            │
# ╰──────────────────────────────────────────────────────────╯

ARG CONTAINER_VERSION=13.3

# ══════════════════════════════════════════════════════════════
# Stage 1: Build OpenClaw from source
# ══════════════════════════════════════════════════════════════
FROM docker.io/gautada/debian:${CONTAINER_VERSION} AS container

# ┌──────────────────────────────────────────────────────────┐
# │ Metadata                                                 │
# └──────────────────────────────────────────────────────────┘
LABEL org.opencontainers.image.title="openclaw"
LABEL org.opencontainers.image.description="Open Claw - Autonomous Agent Platform"
LABEL org.opencontainers.image.url="https://github.com/gautada/openclaw"
LABEL org.opencontainers.image.source="https://github.com/gautada/openclaw"
LABEL org.opencontainers.image.documentation="https://github.com/gautada/openclaw/blob/main/README.md"

# ┌──────────────────────────────────────────────────────────┐
# │ Runtime Dependencies                                     │
# └──────────────────────────────────────────────────────────┘
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    --no-install-recommends ca-certificates curl git jq unzip \
 && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
 && apt-get install -y --no-install-recommends nodejs \
 && apt-get install -y --no-install-recommends \
    chromium \
    fonts-liberation \
    fontconfig \
    libasound2t64 \
    libatk-bridge2.0-0t64 \
    libatspi2.0-0t64 \
    libcairo2 \
    libdbus-1-3 \
    libdrm2 \
    libgbm1 \
    libglib2.0-0t64 \
    libgtk-3-0t64 \
    libnspr4 \
    libnss3 \
    libpango-1.0-0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxkbcommon0 \
    libxrandr2 \
    libxss1 \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/openclaw

# Clone OpenClaw
ARG OPENCLAW_VERSION=main
RUN git config --global advice.detachedHead false \
 && git clone --depth 1 --branch ${OPENCLAW_VERSION} \
         https://github.com/openclaw/openclaw.git . \
 && corepack enable 

# ┌──────────────────────────────────────────────────────────┐
# │ Application User                                         │
# └──────────────────────────────────────────────────────────┘
# Rename base container user (debian) to nyx
ARG USER=cheliped
RUN /usr/sbin/usermod -l $USER debian \
 && /usr/sbin/usermod -d /home/$USER -m $USER \
 && /usr/sbin/groupmod -n $USER debian \
 && /bin/echo "$USER:$USER" | /usr/sbin/chpasswd \
 && rm -rf /home/debian \
 && chown -R $USER:$USER /opt/openclaw

# OpenClaw workspace directory
ENV OPENCLAW_HOME=/home/$USER
USER $USER
RUN pnpm install --frozen-lockfile \     
 && pnpm build \
 && pnpm ui:build

# ┌──────────────────────────────────────────────────────────┐
# │ Service Configuration                                    │
# └──────────────────────────────────────────────────────────┘
USER root
# COPY entrypoint.sh /usr/bin/container-entrypoint
# RUN chmod +x /usr/bin/container-entrypoint

COPY openclaw-running.sh /etc/container/health.d/openclaw-running
# RUN chmod +x /etc/container/health.d/openclaw-running

COPY appversion-check.sh /etc/container/health.d/appversion-check
RUN chmod +x /etc/container/health.d/appversion-check

COPY version.sh /usr/bin/container-version
# RUN chmod +x /usr/bin/container-version

COPY latest.sh /usr/bin/container-latest
RUN chmod +x /usr/bin/container-latest

# s6 service definition
RUN mkdir -p /etc/services.d/openclaw
COPY openclaw-run.sh /etc/services.d/openclaw/run
# RUN chmod +x /etc/services.d/openclaw/run

COPY openclaw.json /home/$USER/.openclaw/openclaw.json

# Permissions
RUN chown -R $USER:$USER /home/$USER
