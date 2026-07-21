#!/bin/sh
set -eu
# Serverpod API on the port configured in config/production.yaml (8080).
exec ./bin/server \
  --mode="${runmode:-production}" \
  --server-id="${serverid:-default}" \
  --logging="${logging:-normal}" \
  --role="${role:-monolith}"
