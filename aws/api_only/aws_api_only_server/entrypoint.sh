#!/bin/sh
set -eu
# Serverpod API on the port configured in config/production.yaml (8080).
# App Runner ImageConfiguration.Port must match.
exec ./bin/server \
  --mode="${runmode:-production}" \
  --server-id="${serverid:-default}" \
  --logging="${logging:-normal}" \
  --role="${role:-monolith}"
