# azure/realtime_monolith

**Azure Container Apps** monolith: Flutter web + Serverpod API + **WebSocket streams**.

```text
Browser ──HTTPS──► Container Apps ingress
                      └─ container
                           nginx :8080
                             ├─ Flutter static
                             └─ proxy → Serverpod :8081  (API + /v1/websocket)
```

Unlike AWS App Runner (managed Envoy **403** on Upgrade), Container Apps
forwards WebSocket upgrades. Same packaging pattern as Cloud Run / ECS monoliths.

## Deploy

```bash
az login
docker
dart pub global activate podfly   # need host: azure (podfly main / ≥ current)

cd azure/realtime_monolith
podfly deploy --yes --smoke
```

Open the printed FQDN → **Start clock stream**.

Cold start can take a bit with `min_replicas: 0`.

### WebSocket probe

```bash
# Force HTTP/1.1 — curl defaults to HTTP/2 on HTTPS, which is not a classic Upgrade.
curl -i -N --http1.1 --max-time 8 \
  -H 'Connection: Upgrade' \
  -H 'Upgrade: websocket' \
  -H 'Sec-WebSocket-Version: 13' \
  -H 'Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==' \
  "https://YOUR_FQDN/v1/websocket"
# expect: HTTP/1.1 101 Switching Protocols
```

## Teardown

```bash
# simplest: delete the resource group from podfly.yaml
az group delete --name podfly-azure-rt-rg --yes --no-wait
```

**Cost:** ACR + Container Apps environment — delete when done.

## See also

- [api_only](../api_only/) — RPC only (no Flutter web)
- [podfly doc/azure.md](https://github.com/127thousand/podfly/blob/main/doc/azure.md)
