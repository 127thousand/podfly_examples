# Netlify examples

Static Flutter web via **`web_host: netlify`** (same role as Cloudflare Pages / Vercel).

| Path | API | UI | Streams |
|------|-----|-----|---------|
| [split_fly](split_fly/) | Fly.io | Netlify | — |
| [realtime_split](realtime_split/) | Fly.io | Netlify | ✅ WS → Fly |

## Why not API / WebSockets on Netlify?

Netlify is a **static CDN**. Serverpod RPC and long-lived **WebSocket streams**
must run on an API host (`host: fly`, …). For realtime, bake `SERVER_URL` to the
API origin so the browser upgrades WSS to Fly, not to `*.netlify.app`.

See [podfly doc/netlify.md](https://github.com/127thousand/podfly/blob/main/doc/netlify.md).

## Prerequisites

```bash
npm i -g netlify-cli
netlify login
# fly auth for the API side
dart pub global activate podfly   # or path activate for contributors
```

## Deploy

```bash
cd netlify/split_fly          # or realtime_split
podfly deploy --yes --smoke
```

## Teardown

```bash
fly apps destroy podfly-netlify-split-api --yes   # or podfly-netlify-rt-api
netlify sites:list
netlify sites:delete <site-id> --force
```
