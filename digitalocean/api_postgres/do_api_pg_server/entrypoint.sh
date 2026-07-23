#!/bin/sh
set -eu
exec ./bin/server \
  --mode="${runmode:-production}" \
  --server-id="${serverid:-default}" \
  --logging="${logging:-normal}" \
  --role="${role:-monolith}" \
  --apply-migrations
