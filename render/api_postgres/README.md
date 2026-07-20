# render/api_postgres

Serverpod **API only** + **Render Postgres**.

## Full walkthrough

See **[../README.md](../README.md)** — why `render.repo` is required and how deploy works.

## Deploy

```bash
# Push monorepo to GitHub; set render.repo in podfly.yaml
render login
dart pub global activate podfly

cd render/api_postgres
podfly deploy --api --yes --smoke
```

No Flutter web in this leaf (`web.enabled: false`).
