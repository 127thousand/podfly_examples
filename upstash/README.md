# Upstash examples

Optional **Redis** for Serverpod multi-instance **cache** and **PubSub** (`redis.provider: upstash`).

| Path | What |
|------|------|
| [pubsub_chat](pubsub_chat/) | Fly HA (2 machines) + Netlify Flutter chat + Upstash — proves **cross-machine** `session.messages` via green CROSS-MACHINE UI |

## When you need this

| Setup | Redis? |
|-------|--------|
| Single Fly machine, local messages only | No (`redis.provider: none`) |
| Multi-instance + shared cache | Yes |
| Multi-instance + `postMessage(..., global: true)` / stream fan-out across machines | Yes |

Static CDNs (Netlify/Vercel/…) still only host Flutter. API + WebSockets stay on Fly (or another WS-capable host). Redis is orthogonal: it coordinates **server processes**, not the browser CDN.

## Prerequisites

```bash
npm i -g @upstash/cli
upstash login
# fly + netlify (or your chosen web_host) as for other split demos
dart pub global activate podfly
```

## Deploy / teardown

See [pubsub_chat/README.md](pubsub_chat/README.md). Short form:

```bash
cd upstash/pubsub_chat
podfly deploy --yes --smoke
# …
fly apps destroy podfly-upstash-chat-api --yes
netlify sites:delete <site-id> --force
upstash redis delete --db-id <id>
```

## Docs

- [podfly — Upstash](https://github.com/127thousand/podfly/blob/main/doc/upstash.md)
- [podfly.yaml — redis](https://github.com/127thousand/podfly/blob/main/doc/podfly.yaml.md)
