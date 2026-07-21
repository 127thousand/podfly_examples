# aws/realtime_monolith

**One App Runner service** = Flutter web UI + Serverpod API (+ stream endpoint code).

Same **container** architecture as [gcp/realtime_monolith](../../gcp/realtime_monolith/):

```text
Browser ──HTTPS :8080──► nginx
                           ├─ static  → Flutter web
                           └─ API/WS  → Serverpod :8081
```

## Demo

1. **RPC** — `greeting.hello` (HTTP) — **works** on App Runner  
2. **Realtime** — `tick.clock` stream (WebSocket) — **does not work on App Runner**

### Why streams fail

App Runner’s edge proxy (**Envoy**) rejects WebSocket upgrades with **HTTP 403**
before traffic reaches nginx/Serverpod:

```bash
curl -i -H 'Connection: Upgrade' -H 'Upgrade: websocket' \
  -H 'Sec-WebSocket-Version: 13' -H 'Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==' \
  https://YOUR_SERVICE.us-east-1.awsapprunner.com/v1/websocket
# → HTTP/1.1 403 Forbidden  (server: envoy)
```

AWS documents App Runner as **HTTP/1.0–1.1 request/response** with a **120s**
request timeout — not long-lived WebSockets. The platform roadmap item for
WebSockets was closed without native support.

| Feature | Cloud Run (`gcp/realtime_monolith`) | App Runner (this example) |
|---------|-------------------------------------|---------------------------|
| Flutter web + RPC | ✅ | ✅ |
| Serverpod method streams (WS) | ✅ | ❌ edge 403 |

For realtime Serverpod on AWS, use **ECS/Fargate + ALB** (WebSocket-capable) or
stay on **Cloud Run** / Fly for the cheap stream demo.

## Deploy

```bash
aws configure   # or SSO
docker          # local build linux/amd64
dart pub global activate podfly

cd aws/realtime_monolith
podfly deploy --yes --smoke
```

Open the printed URL → **Start clock stream**.

### App Runner notes

- `start_command: /app/start.sh` (required; shell ENTRYPOINT alone is flaky)
- `ecr_public: true` in this example (private ECR CREATE often fails with empty logs)
- App Runner is **not** free scale-to-zero — **delete when done**

## Teardown

```bash
aws apprunner list-services --region us-east-1
aws apprunner delete-service --service-arn "$SERVICE_ARN" --region us-east-1
# optional
aws ecr-public delete-repository --repository-name podfly-aws-realtime --region us-east-1 --force
```
