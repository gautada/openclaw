# ╭──────────────────────────────────────────────────────────╮
# │ Nyx Calder - OpenClaw AI Assistant Container            │
# ╰──────────────────────────────────────────────────────────╯

ARG IMAGE_VERSION=13.3

# ══════════════════════════════════════════════════════════════
# Stage 1: Build OpenClaw from source
# ══════════════════════════════════════════════════════════════
FROM docker.io/gautada/debian:${IMAGE_VERSION} AS container

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
    --no-install-recommends ca-certificates curl git unzip \
 && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
 && apt-get install -y --no-install-recommends nodejs \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/openclaw

# Clone OpenClaw
ARG OPENCLAW_VERSION=v2026.02.19
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

COPY version.sh /usr/bin/container-version
# RUN chmod +x /usr/bin/container-version

# s6 service definition
RUN mkdir -p /etc/services.d/openclaw
COPY openclaw-run.sh /etc/services.d/openclaw/run
# RUN chmod +x /etc/services.d/openclaw/run

# Permissions
RUN chown -R $USER:$USER /home/$USER
