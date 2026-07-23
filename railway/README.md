# Railway examples

Serverpod on **Railway** (`host: railway`) via podfly.

| Path | API | UI | Database | Realtime |
|------|-----|-----|----------|----------|
| [api_only](api_only/) | Railway service | — | none | — |
| [api_postgres](api_postgres/) | Railway service | — | `railway_postgres` | — |
| [realtime](realtime/) | Railway service | Railway web (nginx) | none | ✅ WS clock stream |

> **Live demos:** torn down after smoke (2026-07-23). Re-deploy with the steps below.

## Prerequisites

```bash
# https://docs.railway.app/guides/cli
brew install railway   # or curl install script
railway login
dart pub global activate podfly
```

## Deploy

```bash
cd railway/api_only          # or api_postgres / realtime
podfly deploy --api --yes --smoke   # api_* only
# realtime (API + web):
# podfly deploy --yes --smoke
```

podfly creates/links the Railway project, deploys the Dockerfile service, assigns a domain, and (for `api_postgres`) adds the Postgres plugin and wires credentials into Serverpod.

### Realtime

Open the **web** service URL → **Start clock stream**. Streams go to the **API** host (`SERVER_URL`), not the static web origin.

### Postgres password note

`passwords.yaml` is gitignored. After provision, set on the API service if the image lacks the sidecar password:

```bash
railway variable set SERVERPOD_PASSWORD_database='…' -s api
```

(podfly patches local `passwords.yaml` + sidecar; prefer baking password into Fly-style secrets when the file is not uploaded.)

## Teardown

```bash
railway delete -p <project-name-or-id> -y
# e.g. railway delete -p podfly-railway-api -y
```

Verified smoke then destroyed (scheduled delete): `podfly-railway-api`, `podfly-railway-api-pg`, `podfly-railway-rt`.
