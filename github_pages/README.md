# GitHub Pages examples

Static Flutter web via **`web_host: github_pages`**.

| Path | API | UI | Streams |
|------|-----|-----|---------|
| [split_fly](split_fly/) | Fly.io | GitHub Pages | — |
| [realtime_split](realtime_split/) | Fly.io | GitHub Pages | ✅ WS → Fly |

## Why not API / WebSockets on GitHub Pages?

GitHub Pages is a **static site** host. Serverpod RPC and long-lived **WebSocket
streams** run on an API host (`host: fly`, …). For realtime, bake `SERVER_URL`
to the API origin so the browser upgrades WSS to Fly, not to `*.github.io`.

Project sites need **`web.base_href: /<repo>/`** (podfly sets this if left as `/`).

See [podfly doc/github_pages.md](https://github.com/127thousand/podfly/blob/main/doc/github_pages.md).

## Prerequisites

```bash
brew install gh   # https://cli.github.com/
gh auth login     # repo scope
# fly auth for the API side
dart pub global activate podfly
```

## Deploy

```bash
cd github_pages/split_fly          # or realtime_split
podfly deploy --yes --smoke
```

## Teardown

```bash
fly apps destroy <api-app> --yes

# Needs: gh auth refresh -h github.com -s delete_repo
gh repo delete <you>/<repo> --yes
```
