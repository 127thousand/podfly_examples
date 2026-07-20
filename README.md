# podfly_examples

Serverpod deploy demos for **[podfly](https://github.com/127thousand/podfly)** — one repo, many clouds and configs.

```text
podfly_examples/
  fly/
    api_only/           # API-only → Fly (scale-to-zero)
  render/
    api_postgres/       # API + Render Postgres → Render
  railway/              # (planned)
  digitalocean/         # (planned)
```

Each **leaf folder** is a full Serverpod monorepo root (`podfly deploy` cwd).

## Render monorepo note

Render supports `rootDir` so examples need **not** live at the git root. See `render/api_postgres/podfly.yaml` (`render.root_dir`).

## Quick start

```bash
# Install
dart pub global activate podfly

# Fly API-only
cd fly/api_only
podfly deploy --api --yes --smoke

# Render API + Postgres (set render.repo if forking)
cd render/api_postgres
render login   # or RENDER_API_KEY
podfly deploy --api --yes --smoke
```

## Official easy button

For fully managed Serverpod (API, web, Insights): **[Serverpod Cloud](https://serverpod.dev/cloud)**.

podfly is for **your own** infra with less ceremony.
