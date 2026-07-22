# vercel/realtime_split

**Split realtime demo:** Flutter web on **Vercel** + Serverpod API **and WebSocket streams** on **Fly.io**.

```text
Browser UI  ──HTTPS──► Vercel  (static Flutter)
Browser WS  ──WSS───► Fly     (Serverpod /v1/websocket + RPC)
```

Unlike monolith demos, the UI origin is **not** the API origin. The Flutter client
uses `SERVER_URL=https://….fly.dev/` so streams go to Fly.

## Prerequisites

```bash
fly auth login
vercel login
docker
dart pub global activate podfly
```

## Deploy

```bash
cd vercel/realtime_split
podfly deploy --yes --smoke
```

Open the **Vercel** URL → **Start clock stream** (connects to Fly).

### WebSocket probe (against the API host)

```bash
curl -i -N --http1.1 --max-time 8 \
  -H 'Connection: Upgrade' \
  -H 'Upgrade: websocket' \
  -H 'Sec-WebSocket-Version: 13' \
  -H 'Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==' \
  "https://podfly-vercel-rt-api.fly.dev/v1/websocket"
# expect: HTTP/1.1 101 Switching Protocols
```

## Teardown

```bash
fly apps destroy podfly-vercel-rt-api --yes
vercel project remove podfly-vercel-rt-ui
```

## See also

- [split_fly](../split_fly/) — split without streams  
- [hetzner/realtime_monolith](../../hetzner/realtime_monolith/) — same-origin monolith
