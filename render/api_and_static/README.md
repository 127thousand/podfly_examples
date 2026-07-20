# render/api_and_static

Serverpod **API** (Docker web service) + Flutter **web** (Render **static site**).

## Full walkthrough

See **[../README.md](../README.md)** — Render needs a GitHub repo URL; that doc explains the flow end-to-end.

## One-shot deploy

```bash
# 1. Push this monorepo (or your fork) to GitHub
# 2. Set render.repo in podfly.yaml to that URL
render login
dart pub global activate podfly

cd render/api_and_static
podfly deploy --yes --smoke
```

| Surface | Typical URL |
|---------|-------------|
| API | `https://<render.service>.onrender.com/` |
| UI | `https://<render.web_service>.onrender.com/` |

`site/` is the published Flutter web build (podfly commits/pushes it so Render can serve it).
