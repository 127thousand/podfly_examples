# vercel/split_fly

**Split demo:** Serverpod API on **Fly.io** + Flutter web on **Vercel**.

```text
Browser ──► Vercel (Flutter static)
       └──► Fly (Serverpod API /greeting/hello)
```

Same architecture as Cloudflare Pages + Fly, with `web_host: vercel`.

## Prerequisites

```bash
fly auth login
vercel login          # or VERCEL_TOKEN
docker
dart pub global activate podfly   # ≥ 0.7.x with web_host: vercel
```

## Deploy

```bash
cd vercel/split_fly
# fly.app must be unique on Fly
podfly deploy --yes --smoke
```

## Teardown

```bash
fly apps destroy podfly-vercel-split-api --yes
# Vercel: project Settings → Delete, or:
vercel project rm podfly-vercel-split-ui --yes
```

## See also

- [podfly `web_host`](https://github.com/127thousand/podfly/blob/main/doc/podfly.yaml.md#static-web-hosts-web_host)
