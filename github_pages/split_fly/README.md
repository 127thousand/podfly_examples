# GitHub Pages + Fly split

Flutter web on **GitHub Pages** (`web_host: github_pages`); Serverpod API on **Fly**.

```bash
dart pub global activate podfly
cd github_pages/split_fly
podfly deploy --yes --smoke
```

| Layer | Example |
|-------|---------|
| UI | `https://<you>.github.io/podfly-ghp-split-ui/` |
| API | `https://podfly-ghp-split-api.fly.dev` |

Project Pages require `web.base_href: /podfly-ghp-split-ui/` (podfly sets this if you leave `/`).

## Teardown

```bash
fly apps destroy podfly-ghp-split-api --yes
gh repo delete <you>/podfly-ghp-split-ui --yes
```
