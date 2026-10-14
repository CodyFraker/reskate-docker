# syntax=docker/dockerfile:1

ARG RESKATE_RELEASE=latest

FROM debian:13-slim AS bundled
ARG RESKATE_RELEASE
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl jq tar \
    && rm -rf /var/lib/apt/lists/*
COPY scripts/install-server.sh /usr/local/bin/install-server.sh
RUN chmod +x /usr/local/bin/install-server.sh
ENV RELEASE="${RESKATE_RELEASE}"
RUN SERVER_DIR=/opt/reskate-bundled /usr/local/bin/install-server.sh

FROM debian:13-slim
ARG IMAGE_SOURCE=https://github.com/Shrimp/reskate-docker
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl jq tar \
    && rm -rf /var/lib/apt/lists/*

COPY --from=bundled /opt/reskate-bundled /opt/reskate-bundled
COPY scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /server
VOLUME ["/server"]

LABEL org.opencontainers.image.title="reskate-docker" \
    org.opencontainers.image.description="Unofficial ReSkate dedicated server" \
    org.opencontainers.image.source="${IMAGE_SOURCE}"

ENTRYPOINT ["/entrypoint.sh"]
