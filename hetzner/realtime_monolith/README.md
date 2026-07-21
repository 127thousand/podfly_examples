# hetzner/realtime_monolith

**Hetzner Cloud VPS** monolith: Flutter web + Serverpod API + **WebSocket streams**.

```text
Browser ──HTTPS :443──► Caddy (Let's Encrypt, PTR or custom domain)
                           └─ reverse_proxy → Docker
                                nginx :8080
                                  ├─ Flutter static
                                  └─ proxy → Serverpod :8081  (API + /v1/websocket)
```

## Deploy

```bash
hcloud context active   # token + SSH key already set up
docker
dart pub global activate podfly

cd hetzner/realtime_monolith
podfly deploy --yes --smoke
```

Open the printed `https://…` URL → **Start clock stream**.

### WebSocket probe

```bash
curl -i -N --http1.1 --max-time 8 \
  -H 'Connection: Upgrade' \
  -H 'Upgrade: websocket' \
  -H 'Sec-WebSocket-Version: 13' \
  -H 'Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==' \
  "https://YOUR_HOST/v1/websocket"
# expect: HTTP/1.1 101 Switching Protocols
```

## Teardown

```bash
hcloud server delete podfly-hetzner-demo
```

## See also

- [api_only](../api_only/) — RPC only  
- [podfly doc/hetzner.md](https://github.com/127thousand/podfly/blob/main/doc/hetzner.md)
