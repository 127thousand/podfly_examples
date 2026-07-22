# podfly_examples

Serverpod deploy demos for **[podfly](https://github.com/127thousand/podfly)** — one repo, many clouds and configs.

```text
podfly_examples/
  fly/
    api_only/           # API-only → Fly (scale-to-zero)
  render/
    README.md           # ★ how Render + git works (read this)
    api_postgres/       # API + Render Postgres
    api_and_static/     # API + Flutter web static site
  railway/              # (planned)
  gcp/
    README.md           # ★ Cloud Run notes (one-port monolith)
    api_only/           # API-only → Cloud Run (cheap serverless)
    realtime_monolith/  # Flutter web + API + WebSocket streams (nginx monolith)
  aws/
    README.md           # ★ App Runner vs ECS (WebSockets)
    api_only/           # API-only → App Runner
    realtime_monolith/  # Flutter + RPC on App Runner (no WS)
    ecs_realtime/       # Flutter + RPC + WebSocket streams → ECS Fargate + ALB
  azure/
    README.md           # ★ Container Apps notes
    api_only/           # API-only → Azure Container Apps
    realtime_monolith/  # Flutter web + API + WebSocket streams
  hetzner/
    README.md           # ★ VPS + Caddy HTTPS notes
    api_only/           # API-only → Hetzner Cloud (Docker/SSH)
    realtime_monolith/  # Flutter web + API + WebSocket streams
  vercel/
    README.md           # ★ web_host: vercel (static Flutter)
    split_fly/          # Fly API + Vercel Flutter web
    realtime_split/     # Fly API + WS + Vercel Flutter (streams)
  netlify/
    README.md           # ★ web_host: netlify (static Flutter)
    split_fly/          # Fly API + Netlify Flutter web
    realtime_split/     # Fly API + WS + Netlify Flutter (streams)
  github_pages/
    README.md           # ★ web_host: github_pages (static Flutter)
    split_fly/          # Fly API + GitHub Pages Flutter web
    realtime_split/     # Fly API + WS + GitHub Pages Flutter (streams)
  upstash/
    README.md           # ★ redis.provider: upstash (cache / PubSub)
    pubsub_chat/        # Fly HA + Netlify chat + Redis (cross-machine proof)
  digitalocean/         # (planned)
```

Each **leaf folder** is a full Serverpod monorepo root (`podfly deploy` cwd).

## Static web CDNs (`web_host`)

Vercel, Netlify, and GitHub Pages examples only host **Flutter web**. Serverpod
API (+ WebSockets for `realtime_split`) runs on **Fly**. Point `SERVER_URL` at
the API host — never open streams against the CDN origin.

| `web_host` | CLI | Example dirs |
|------------|-----|----------------|
| `cloudflare` | `wrangler` | (default; see CF Pages in podfly docs) |
| `vercel` | `vercel` | `vercel/split_fly`, `vercel/realtime_split` |
| `netlify` | `netlify` | `netlify/split_fly`, `netlify/realtime_split` |
| `github_pages` | `gh` + `git` | `github_pages/split_fly`, `github_pages/realtime_split` |

## Upstash Redis (optional)

Multi-instance **cache** and **PubSub** (`redis.provider: upstash`). Not a web host —
pairs with Fly (or another multi-machine API) so `postMessage(..., global: true)`
fans out across processes.

→ **[upstash/README.md](upstash/README.md)** — `pubsub_chat` (2-machine CROSS-MACHINE proof).

## Render (important)

Render **requires a GitHub/GitLab repo URL**. It does not deploy from a bare local folder like Fly.

→ **[render/README.md](render/README.md)** — step-by-step: repo, `root_dir`, `podfly deploy`, static `site/`, secrets, teardown.

## Google Cloud Run

→ **[gcp/README.md](gcp/README.md)** — API-only vs nginx monolith (Flutter + WebSockets).

## AWS

→ **[aws/README.md](aws/README.md)** — App Runner (HTTP) vs **ECS + ALB** (streams).

App Runner does **not** support WebSockets. Use `aws/ecs_realtime` for Serverpod streams.

## Azure

→ **[azure/README.md](azure/README.md)** — Container Apps (Docker → ACR).

```bash
cd azure/api_only
podfly deploy --api --yes --smoke
# when done: az group delete --name <resource_group> --yes --no-wait
```

## Hetzner Cloud

→ **[hetzner/README.md](hetzner/README.md)** — VPS + Docker over SSH + Caddy HTTPS.

```bash
hcloud context create … && hcloud ssh-key create …
cd hetzner/realtime_monolith
podfly deploy --yes --smoke
# when done: hcloud server delete <name-or-id>
```

## Quick start

```bash
dart pub global activate podfly

# Fly API-only (local → Fly; no git URL required)
cd fly/api_only
podfly deploy --api --yes --smoke

# Render (push to GitHub first, set render.repo in podfly.yaml)
cd render/api_and_static
render login
podfly deploy --yes --smoke

# Cloud Run monolith (Flutter web + realtime streams)
cd gcp/realtime_monolith
# set cloud_run.project in podfly.yaml
podfly deploy --yes --smoke
# when done: gcloud run services delete podfly-gcr-realtime --region us-central1 --quiet

# AWS: streams need ECS + ALB (not App Runner)
cd aws/ecs_realtime
podfly deploy --yes --smoke
# when done: see aws/ecs_realtime/README teardown
```

## Official easy button

For fully managed Serverpod (API, web, Insights): **[Serverpod Cloud](https://serverpod.dev/cloud)**.

podfly is for **your own** infra with less ceremony.
