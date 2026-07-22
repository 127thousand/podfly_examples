# Netlify + Fly realtime split

Flutter web on **Netlify**; Serverpod API **and WebSocket streams** on **Fly**.

Netlify is static-only (like Vercel / Pages) — it cannot terminate Serverpod WSS.
The Flutter app sets `SERVER_URL` to the Fly API and avoids same-origin fallback
when the page is on `*.netlify.app`, so streams upgrade to Fly.

```bash
dart pub global activate podfly
cd netlify/realtime_split
podfly deploy --yes --smoke
```

| Layer | After deploy (example names) |
|-------|------------------------------|
| UI | `https://podfly-netlify-rt-ui.netlify.app` |
| API + WSS | `https://podfly-netlify-rt-api.fly.dev` |

In the UI: **Start clock stream** to verify ticks over WSS.

## Teardown

```bash
fly apps destroy podfly-netlify-rt-api --yes
netlify sites:list
netlify sites:delete <site-id-for-podfly-netlify-rt-ui> --force
```
