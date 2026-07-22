# GitHub Pages + Fly realtime split

Flutter web on **GitHub Pages**; Serverpod API **and WebSocket streams** on **Fly**.

GitHub Pages is static-only — it cannot terminate Serverpod WSS. The Flutter app
sets `SERVER_URL` to Fly and avoids same-origin fallback on `*.github.io`.

```bash
podfly deploy --yes --smoke
```

| Layer | Example |
|-------|---------|
| UI | `https://<you>.github.io/podfly-gpages-rt-ui/` |
| API + WSS | `https://podfly-gpages-rt-api.fly.dev` |

Project Pages need `web.base_href: /podfly-gpages-rt-ui/` (podfly auto-sets if left as `/`).

## Teardown

```bash
fly apps destroy podfly-gpages-rt-api --yes
gh repo delete <you>/podfly-gpages-rt-ui --yes
```
