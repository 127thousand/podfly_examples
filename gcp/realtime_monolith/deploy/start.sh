#!/bin/sh
set -e
# Cloud Run sets PORT (default 8080). nginx must listen on it.
PORT="${PORT:-8080}"
sed -i "s/listen 8080;/listen ${PORT};/" /etc/nginx/conf.d/default.conf

# Serverpod API + WebSockets on 8081 (see config/production.yaml).
./bin/server --mode="${runmode:-production}" --server-id="${serverid:-default}" \
  --logging="${logging:-normal}" --role="${role:-monolith}" &
# Wait for API port before nginx starts accepting traffic.
i=0
while [ "$i" -lt 60 ]; do
  if nc -z 127.0.0.1 8081 2>/dev/null; then
    break
  fi
  i=$((i + 1))
  sleep 0.25
done
# Cloud Run health checks hit $PORT → nginx.
exec nginx -g 'daemon off;'
