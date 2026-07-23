# DigitalOcean examples

Serverpod on **App Platform** (`host: digitalocean`) via podfly + **DOCR** images.

| Path | API | UI | Database | Realtime |
|------|-----|-----|----------|----------|
| [api_only](api_only/) | App Platform | — | none | — |
| [api_postgres](api_postgres/) | App Platform | — | Managed Postgres | — |
| [realtime](realtime/) | App Platform | Web app (nginx) | none | ✅ WS clock stream |

> **Live demos:** torn down after smoke (2026-07-23). Re-deploy with the steps below.

## Prerequisites

```bash
brew install doctl
doctl auth init
# One container registry (Starter: single repo OK)
doctl registry create ben-registry --subscription-tier starter   # if missing
# Docker Desktop (or engine) running for local build → push
dart pub global activate podfly
```

## Deploy

```bash
cd digitalocean/api_only     # or api_postgres / realtime
podfly deploy --api --yes --smoke   # api_* only
# realtime:
# podfly deploy --yes --smoke
```

podfly builds `linux/amd64` images, pushes to DOCR, upserts the App Spec, and for Postgres provisions Managed DB + app firewall rule.

**Starter DOCR:** only **one repository**. Share it with `api_repository` + distinct `image_tag` (see `api_postgres` / `realtime` `podfly.yaml`).

**Cost note:** Managed Postgres is billed even when the app sleeps. Tear down the cluster when done.

### Realtime

Open the **web** app URL → **Start clock stream**. WSS targets the **API** app (`SERVER_URL`).

## Teardown

```bash
doctl apps list
doctl apps delete <app-id> --force
doctl databases list
doctl databases delete <cluster-id> --force
# optional: prune DOCR tags
```

Verified smoke then destroyed: `podfly-do-api`, `podfly-do-api-pg`, `podfly-do-rt`, `podfly-do-rt-web`, and managed DB `podfly-do-api-pg-db`.
