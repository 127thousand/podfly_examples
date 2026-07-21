#!/bin/sh
set -e
PORT="${PORT:-8080}"
sed -i "s/listen 8080;/listen ${PORT};/" /etc/nginx/conf.d/default.conf

./bin/server --mode="${runmode:-production}" --server-id="${serverid:-default}" \
  --logging="${logging:-normal}" --role="${role:-monolith}" &
i=0
while [ "$i" -lt 60 ]; do
  if nc -z 127.0.0.1 8081 2>/dev/null; then
    break
  fi
  i=$((i + 1))
  sleep 0.25
done
exec nginx -g 'daemon off;'
