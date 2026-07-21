# aws/realtime_monolith

**One App Runner service** = Flutter web UI + Serverpod API + **WebSocket streams**.

Same architecture as [gcp/realtime_monolith](../../gcp/realtime_monolith/):

```text
Browser ──HTTPS :8080──► nginx
                           ├─ static  → Flutter web
                           └─ API/WS  → Serverpod :8081
```

## Demo

1. **RPC** — `greeting.hello` (HTTP)
2. **Realtime** — `tick.clock` stream (WebSocket)

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
