# App Runner monolith: Flutter web (static) + Serverpod API/WebSockets
# nginx :8080  →  static files  |  proxy → Serverpod :8081
#
# Build from this directory (monorepo leaf):
#   docker build --platform linux/amd64 -t aws-rt .
# podfly sets App Runner StartCommand=/app/start.sh

# ── Flutter web ──────────────────────────────────────────────
FROM ghcr.io/cirruslabs/flutter:stable AS flutter
WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
COPY aws_rt_flutter aws_rt_flutter
COPY aws_rt_client aws_rt_client
# Minimal workspace for flutter package resolution
RUN printf '%s\n' \
  'name: _' \
  'environment:' \
  '  sdk: ^3.5.0' \
  'workspace:' \
  '  - aws_rt_flutter' \
  '  - aws_rt_client' \
  > pubspec.yaml
WORKDIR /app/aws_rt_flutter
# Do not bake SERVER_URL: main.dart uses same-origin (Uri.base) on web when
# assets/config.json still points at localhost (App Runner monolith).
RUN flutter pub get && \
    flutter build web --release --base-href /

# ── Serverpod API ────────────────────────────────────────────
FROM dart:3.10.3 AS server
WORKDIR /app
COPY pubspec.lock .
COPY aws_rt_server aws_rt_server
RUN printf '%s\n' \
  'name: _' \
  'environment:' \
  '  sdk: ^3.10.3' \
  'workspace:' \
  '  - aws_rt_server' \
  > pubspec.yaml
RUN dart pub get
WORKDIR /app/aws_rt_server
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

# Dart runtime pieces from server build
COPY --from=server /runtime/ /
COPY --from=server /app/aws_rt_server/build/bundle/ ./
COPY --from=server /app/aws_rt_server/config/ config/
COPY --from=server /app/aws_rt_server/lib/src/generated/protocol.yaml \
  lib/src/generated/protocol.yaml

# Flutter web
COPY --from=flutter /app/aws_rt_flutter/build/web /app/public

# nginx + entrypoint
COPY deploy/nginx.conf /etc/nginx/conf.d/default.conf
COPY deploy/start.sh /app/start.sh
RUN chmod +x /app/start.sh \
    && rm -f /etc/nginx/conf.d/default.conf.bak 2>/dev/null || true

# App Runner port 8080 (nginx). Serverpod is internal on 8081.
EXPOSE 8080
ENTRYPOINT ["/app/start.sh"]
