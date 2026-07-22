# Netlify + Fly split (HTTP RPC)

Flutter web on **Netlify** (`web_host: netlify`); Serverpod API on **Fly**.

No WebSocket streams in this example — see [../realtime_split](../realtime_split/)
for clock streams over WSS to Fly.

```bash
dart pub global activate podfly
cd netlify/split_fly
podfly deploy --yes --smoke
```

| Layer | After deploy (example names) |
|-------|------------------------------|
| UI | `https://podfly-netlify-split-ui.netlify.app` |
| API | `https://podfly-netlify-split-api.fly.dev` |

## Teardown

```bash
fly apps destroy podfly-netlify-split-api --yes
netlify sites:list
netlify sites:delete <site-id-for-podfly-netlify-split-ui> --force
```
