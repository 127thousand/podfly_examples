# DigitalOcean realtime (API + web + WebSockets)

App Platform: **API app** + **web app** (nginx Flutter static). Streams hit the API host.

> **Live demo:** torn down after smoke (2026-07-23).

Open the UI → **Start clock stream**. Starter DOCR shares `podfly-do-api` tags `rt` / `web`.

```bash
cd digitalocean/realtime
podfly deploy --yes --smoke
```

See [../README.md](../README.md).
