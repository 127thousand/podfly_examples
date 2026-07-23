#!/bin/sh
set -eu
# Apply Serverpod migrations on boot so Supabase schema is ready.
exec ./bin/server \
  --mode="${runmode:-production}" \
  --server-id="${serverid:-default}" \
  --logging="${logging:-normal}" \
  --role="${role:-monolith}" \
  --apply-migrations
