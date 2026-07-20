# render/api_and_static

Serverpod API (Docker web service) + Flutter web (**Render static site**).

```bash
dart pub global activate podfly
cd render/api_and_static
podfly deploy --yes --smoke
```

- API: `podfly-render-web-api.onrender.com`
- UI: `podfly-render-web-ui.onrender.com` (static)
- `site/` is the published Flutter web build (git-synced for Render)
