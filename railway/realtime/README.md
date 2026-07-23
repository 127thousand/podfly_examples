# Railway realtime (API + web + WebSockets)

Native Railway: **api** service (Serverpod) + **web** service (nginx Flutter static).

> **Live demo:** torn down after smoke (2026-07-23).

Open the UI → **Start clock stream** (WSS to API). RPC: `greeting.hello`.

```bash
cd railway/realtime
podfly deploy --yes --smoke
```

See [../README.md](../README.md).
