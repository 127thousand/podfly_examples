# gcp/realtime_monolith

**One Cloud Run service** = Flutter web UI + Serverpod API + **WebSocket streams**.

## Can Cloud Run do monolith?

**Yes** — with a single container (not multi-port Serverpod):

```text
Browser ──HTTPS :8080──► nginx
                           ├─ static files  → Flutter web (build/web)
                           └─ other / WS   → proxy → Serverpod :8081
```

Cloud Run only exposes **one public port**. Serverpod’s default multi-port layout
(API 8080 / web 8082) does not map cleanly. This image runs:

| Process | Port | Role |
|---------|------|------|
| **nginx** | `8080` (`$PORT`) | Ingress: SPA + WebSocket-capable reverse proxy |
| **Serverpod** | `8081` (localhost only) | Endpoints + stream WebSockets |

No Redis needed for this demo (single-instance in-process stream).

## Demo features

1. **RPC** — `greeting.hello` (HTTP)
2. **Realtime** — `tick.clock` stream (WebSocket), ticks every second

## Deploy

```bash
gcloud auth login
gcloud config set project YOUR_PROJECT
# enable APIs + Cloud Build SA permissions (first time)

dart pub global activate podfly
cd gcp/realtime_monolith

# Edit cloud_run.project in podfly.yaml, then:
podfly deploy --yes --smoke
```

Open the printed Cloud Run URL in a browser → **greeting.hello** (RPC) and
**Start clock stream** (WebSocket method stream).

Cloud Run flags used for realtime:

- `timeout_seconds: 3600` — long-lived stream requests
- `session_affinity: true` — sticky routing when scaled > 1
- `execution_environment: gen2` — Cloud Run 2nd gen (pinned by podfly)

No Redis: single-instance in-process streams are enough for this demo.

## Local Docker (optional)

```bash
docker build -t gcr-rt .
docker run --rm -p 8080:8080 gcr-rt
# open http://localhost:8080  (UI uses same-origin for the API)
```

## Teardown

```bash
gcloud run services delete podfly-gcr-realtime --region us-central1 --quiet
```
