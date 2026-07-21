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

### Why streams fail (not an nginx config issue)

App Runner’s **managed** edge (**Envoy**) rejects WebSocket upgrades with
**HTTP 403** *before* traffic reaches nginx/Serverpod:

```bash
curl -i -H 'Connection: Upgrade' -H 'Upgrade: websocket' \
  -H 'Sec-WebSocket-Version: 13' -H 'Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==' \
  https://YOUR_SERVICE.us-east-1.awsapprunner.com/v1/websocket
# → HTTP/1.1 403 Forbidden  (server: envoy)
```

- **Envoy can** proxy WebSockets when you own the proxy (ECS/EKS).
- **App Runner does not** expose Envoy/WS settings — no toggle on CreateService.
- AWS docs: HTTP/1.0–1.1, **120s** request timeout, stateless request model.
- Roadmap [Support web sockets #13](https://github.com/aws/apprunner-roadmap/issues/13): closed not planned.

| Feature | Cloud Run | App Runner (this example) | ECS + ALB (planned) |
|---------|-----------|---------------------------|---------------------|
| Flutter web + RPC | ✅ | ✅ | ✅ |
| Serverpod streams (WS) | ✅ | ❌ edge 403 | ✅ |

Details: [podfly `doc/aws.md`](https://github.com/127thousand/podfly/blob/main/doc/aws.md).  
Next AWS stream path: [ECS Fargate + ALB sketch](https://github.com/127thousand/podfly/blob/main/doc/specs/2026-07-21-aws-ecs-realtime-sketch.md).

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
