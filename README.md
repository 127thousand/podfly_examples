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
  digitalocean/         # (planned)
```

Each **leaf folder** is a full Serverpod monorepo root (`podfly deploy` cwd).

## Render (important)

Render **requires a GitHub/GitLab repo URL**. It does not deploy from a bare local folder like Fly.

→ **[render/README.md](render/README.md)** — step-by-step: repo, `root_dir`, `podfly deploy`, static `site/`, secrets, teardown.

## Google Cloud Run

→ **[gcp/README.md](gcp/README.md)** — API-only vs nginx monolith (Flutter + WebSockets).

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
```

## Official easy button

For fully managed Serverpod (API, web, Insights): **[Serverpod Cloud](https://serverpod.dev/cloud)**.

podfly is for **your own** infra with less ceremony.
