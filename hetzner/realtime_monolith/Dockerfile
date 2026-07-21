# Hetzner Cloud monolith: Flutter web + Serverpod API/WebSockets
# nginx :8080  →  static files  |  proxy → Serverpod :8081
# Host: Caddy :443 → container :8080 (TLS + WS Upgrade)
#
# Build from this directory:
#   docker build --platform linux/amd64 -t hetzner-rt .

# ── Flutter web ──────────────────────────────────────────────
FROM ghcr.io/cirruslabs/flutter:stable AS flutter
WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
COPY hetzner_rt_flutter hetzner_rt_flutter
COPY hetzner_rt_client hetzner_rt_client
RUN printf '%s\n' \
  'name: _' \
  'environment:' \
  '  sdk: ^3.5.0' \
  'workspace:' \
  '  - hetzner_rt_flutter' \
  '  - hetzner_rt_client' \
  > pubspec.yaml
WORKDIR /app/hetzner_rt_flutter
# main.dart uses same-origin (Uri.base) when config points at localhost.
RUN flutter pub get && \
    flutter build web --release --base-href /

# ── Serverpod API ────────────────────────────────────────────
FROM dart:3.10.3 AS server
WORKDIR /app
COPY pubspec.lock .
COPY hetzner_rt_server hetzner_rt_server
RUN printf '%s\n' \
  'name: _' \
  'environment:' \
  '  sdk: ^3.10.3' \
  'workspace:' \
  '  - hetzner_rt_server' \
  > pubspec.yaml
RUN dart pub get
WORKDIR /app/hetzner_rt_server
RUN dart build cli --target bin/main.dart --output build && \
    mv build/bundle/bin/main build/bundle/bin/server && \
    mkdir -p config web migrations

# ── Runtime: nginx + server ──────────────────────────────────
FROM nginx:1.27-alpine
RUN apk add --no-cache libstdc++ ca-certificates netcat-openbsd \
    && rm -rf /var/cache/apk/*

WORKDIR /app
ENV runmode=production
ENV serverid=default
ENV logging=normal
ENV role=monolith

COPY --from=server /runtime/ /
COPY --from=server /app/hetzner_rt_server/build/bundle/ ./
COPY --from=server /app/hetzner_rt_server/config/ config/
COPY --from=server /app/hetzner_rt_server/lib/src/generated/protocol.yaml \
  lib/src/generated/protocol.yaml

COPY --from=flutter /app/hetzner_rt_flutter/build/web /app/public

COPY deploy/nginx.conf /etc/nginx/conf.d/default.conf
COPY deploy/start.sh /app/start.sh
RUN chmod +x /app/start.sh \
    && rm -f /etc/nginx/conf.d/default.conf.bak 2>/dev/null || true

EXPOSE 8080
ENTRYPOINT ["/app/start.sh"]
