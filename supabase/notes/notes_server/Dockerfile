# Build from monorepo root:
# docker build -f notes_server/Dockerfile .

FROM dart:3.10.3 AS build
WORKDIR /app
COPY pubspec.lock .
COPY notes_server notes_server
RUN printf '%s\n' \
  'name: _' \
  'environment:' \
  '  sdk: ^3.10.3' \
  'workspace:' \
  '  - notes_server' \
  > pubspec.yaml
RUN dart pub get
WORKDIR /app/notes_server
RUN dart build cli --target bin/main.dart --output build \
  && mv build/bundle/bin/main build/bundle/bin/server \
  && mkdir -p config web migrations

FROM alpine:3.20
RUN apk add --no-cache libstdc++ ca-certificates
WORKDIR /app
ENV runmode=production
ENV serverid=default
ENV logging=normal
ENV role=monolith
COPY --from=build /runtime/ /
COPY --from=build /app/notes_server/build/bundle/ ./
COPY --from=build /app/notes_server/config/ config/
COPY --from=build /app/notes_server/web/ web/
COPY --from=build /app/notes_server/migrations/ migrations/
COPY --from=build /app/notes_server/lib/src/generated/protocol.yaml \
  lib/src/generated/protocol.yaml
COPY notes_server/entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh
EXPOSE 8080
ENTRYPOINT ["/app/entrypoint.sh"]
