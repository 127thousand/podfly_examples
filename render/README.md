# Deploy Serverpod to Render with podfly

Render is **git-first**: services build from a GitHub/GitLab/Bitbucket repo.  
That is different from Fly (`fly deploy` from your local tree).  
**podfly** still gives you one command — but the source of truth for what Render builds must live in a remote git URL.

This guide is step-by-step for the examples under `render/`.

---

## Mental model

```text
Your machine                         GitHub                         Render
─────────────                        ──────                         ──────
edit code  ──push──►  repo (podfly_examples or yours)
podfly deploy  ──────────────────►  create/update service
                                      (repo + branch + rootDir)
                 ◄── clone & build ──  Dockerfile / site/
                 ──  *.onrender.com live
```

| Piece | Who owns it |
|-------|-------------|
| **Source code + Dockerfile** | Git remote (`render.repo`) |
| **Which folder in the monorepo** | `render.root_dir` → Render **Root Directory** |
| **API password / secrets** | Env vars (e.g. `SERVERPOD_PASSWORD_database`), not git |
| **Flutter web static files** | Built **locally** by podfly, committed to `site/`, then Render publishes that folder |
| **Orchestration** | `podfly deploy` + `render` CLI |

### Why a GitHub URL is required

Render’s CLI creates services like:

```bash
render services create \
  --type web_service \
  --runtime docker \
  --repo https://github.com/YOU/YOUR_REPO \
  --root-directory render/api_and_static \
  …
```

There is no “upload this folder from my laptop” path for normal web/static services.  
Render clones `render.repo` and builds from the commit on `render.branch`.

**podfly.yaml must include:**

```yaml
render:
  repo: https://github.com/YOU/YOUR_REPO   # required
  branch: main
  root_dir: render/api_and_static          # monorepo leaf (optional but used here)
  service: my-api-name
```

---

## Prerequisites (once per machine)

1. **Accounts**
   - [GitHub](https://github.com) (or GitLab/Bitbucket — same idea)
   - [Render](https://dashboard.render.com)

2. **Tools**

   ```bash
   dart pub global activate podfly   # or pin a version
   brew install render               # https://render.com/docs/cli
   # Flutter only if you deploy web (api_and_static)
   ```

3. **Auth**

   ```bash
   render login
   render workspace set   # pick your workspace if prompted
   ```

   CI later: set `RENDER_API_KEY` instead of browser login.

4. **Optional:** connect GitHub to Render in the [Dashboard](https://dashboard.render.com)  
   (private repos need this; public repos often clone without it, but connecting is recommended).

---

## Step-by-step: use these examples

### 1. Get the monorepo on GitHub

Fork or clone **this** repo so you have a remote URL:

```bash
git clone https://github.com/127thousand/podfly_examples.git
cd podfly_examples
# If you forked, use your remote:
# git remote set-url origin https://github.com/YOU/podfly_examples.git
```

Every leaf under `render/` is already a Serverpod monorepo root.  
`root_dir` points Render at that leaf, **not** the monorepo root.

| Leaf | What it deploys |
|------|------------------|
| [`api_postgres/`](api_postgres/) | API only + Render Postgres |
| [`api_and_static/`](api_and_static/) | API + Flutter web **static site** |

### 2. Point `podfly.yaml` at *your* repo

Edit the leaf you want, e.g. `render/api_and_static/podfly.yaml`:

```yaml
host: render
# …

render:
  service: my-unique-api-name          # global-ish name on your workspace
  web_service: my-unique-ui-name       # static site (web example only)
  region: oregon
  plan: free                           # change when you leave free tier
  branch: main
  repo: https://github.com/YOU/podfly_examples   # ← must match git remote
  root_dir: render/api_and_static                # path inside that repo
  site_dir: site                                 # published Flutter web (web example)
```

**Checklist**

- [ ] `render.repo` is the **HTTPS** (or git) URL of the remote Render will clone  
- [ ] That remote has the same commits you think you’re deploying  
- [ ] `render.root_dir` matches the leaf path in the repo  
- [ ] Service names don’t collide with existing Render services  

### 3. Push your code **before** the first deploy

Render builds from **remote** git, not uncommitted local edits.

```bash
git add -A
git commit -m "Ready for Render"
git push -u origin main
```

Dockerfile for the API lives at the **leaf root** (e.g. `render/api_and_static/Dockerfile`) because the Render CLI defaults to `./Dockerfile` under `rootDir`.

### 4. Run podfly from the leaf

```bash
cd render/api_and_static   # or api_postgres
podfly deploy --yes --smoke
```

#### What happens (API + static)

| Step | What podfly / Render do |
|------|-------------------------|
| 1 | Doctor: `render` CLI + login / `RENDER_API_KEY` |
| 2 | Database (if `render_postgres`): `render postgres create`, patch Serverpod config, set `SERVERPOD_PASSWORD_database` |
| 3 | **API service**: create Docker `web_service` with `--repo` + `--root-directory` if missing |
| 4 | **Deploy API**: `render deploys create <id> --wait` → Render clones GitHub and builds the Dockerfile |
| 5 | **Flutter web** (if `web.enabled: true`): local `flutter build web` with live `SERVER_URL` |
| 6 | Stage build → `site/`, **git commit + push** so GitHub has the static assets |
| 7 | **Static site**: create `static_site` with `publish-directory: site` if missing |
| 8 | **Deploy UI**: Render clones again and publishes `site/` |
| 9 | Smoke HTTP checks |

#### API only (`api_postgres`)

Same through step 4 (+ Postgres). No Flutter build / no static site.

### 5. Open the URLs

After a successful deploy:

```text
API:  https://<render.service>.onrender.com/
UI:   https://<render.web_service>.onrender.com/   # if web enabled
```

Names come from `podfly.yaml` (`service` / `web_service`).

### 6. Iterate (day-to-day)

```bash
# 1) Change code
# 2) Commit + push so Render can see it
git add -A && git commit -m "feat: …" && git push

# 3) Redeploy (podfly or Render auto-deploy on push if enabled)
cd render/api_and_static
podfly deploy --yes --smoke
```

For **static UI**, podfly will rebuild Flutter, update `site/`, and push that folder again.

---

## Greenfield (your own Serverpod app)

1. Create a **GitHub repo** and push a normal Serverpod monorepo (`*_server`, optional `*_flutter`).

2. At the monorepo root (or in a leaf folder if you use a monorepo of demos):

   ```bash
   # Dockerfile at the path Render will use as rootDir root:
   # prefer Serverpod’s Dockerfile; copy to rootDir/Dockerfile if needed
   ```

3. Init / write `podfly.yaml`:

   ```yaml
   host: render
   mode: monolith
   name: my_app
   server: my_app_server
   flutter: my_app_flutter

   render:
     service: my-app-api
     web_service: my-app-ui          # omit if API-only
     repo: https://github.com/YOU/my_app
     branch: main
     root_dir: .                     # or path inside a monorepo
     site_dir: site

   database:
     provider: none                  # or render_postgres
   # render_postgres:
   #   name: my-app-db
   #   create: true
   #   plan: free
   #   region: oregon

   web:
     enabled: true                   # false = API only
     api_url: https://my-app-api.onrender.com/
   ```

4. Push to GitHub, then:

   ```bash
   render login
   podfly deploy --yes --smoke
   ```

---

## Monorepo layout (this repo)

```text
podfly_examples/                          ← git remote root (render.repo)
  render/
    api_and_static/                       ← root_dir for that demo
      Dockerfile                          ← API image (at leaf root)
      podfly.yaml
      site/                               ← Flutter web publish dir (generated)
      my_app_server/
      my_app_flutter/
    api_postgres/
      Dockerfile
      podfly.yaml
      …
```

Render **Root Directory** = `render/api_and_static`  
Build context for Docker = that folder only (files outside `root_dir` are not available).

---

## Secrets and config (important)

| Item | In git? | How it gets to Render |
|------|---------|------------------------|
| Source, Dockerfile | Yes | Clone from `render.repo` |
| `config/production.yaml` host/user/db | Yes (no passwords) | Baked into Docker image on build |
| DB password | **No** | `SERVERPOD_PASSWORD_database` env on create |
| `config/passwords.yaml` | **No** (gitignore) | Prefer env var above |
| Flutter `site/` | Yes (generated) | Static site `publish-directory` |

Do **not** commit real production passwords.

---

## CI sketch

```yaml
# .github/workflows/deploy-render.yml (idea)
env:
  RENDER_API_KEY: ${{ secrets.RENDER_API_KEY }}
steps:
  - uses: actions/checkout@v4
  - uses: dart-lang/setup-dart@v1
  - uses: subosito/flutter-action@v2   # if web.enabled
  - run: dart pub global activate podfly
  - run: |
      # install render CLI
      curl -fsSL https://raw.githubusercontent.com/render-oss/cli/refs/heads/main/bin/install.sh | sh
  - run: podfly deploy --yes --no-login --smoke
    working-directory: render/api_and_static
```

Push already updated the repo; `podfly deploy` creates/redeploys Render services against that commit.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Create fails / “no access to repo” | Private repo not linked | Connect GitHub in Render Dashboard |
| `Dockerfile: no such file` | Wrong `root_dir` or Dockerfile not at leaf root | Put Dockerfile at `root_dir/Dockerfile` |
| API missing password | Env not set | Redeploy so podfly sets `SERVERPOD_PASSWORD_database` |
| DB connection refused | Empty IP allow list / wrong host | podfly opens `0.0.0.0/0`; prefer **internal** PG host on same workspace |
| Static site empty / old | `site/` not pushed | Ensure git push of `site/` succeeded |
| Wrong `*.onrender.com` | Stale `public_host` in yaml | Set `render.service` / redeploy; check Dashboard URL |

---

## Teardown (stop billing)

```bash
render services          # list
render services delete <srv-…> --confirm
render postgres delete <dpg-…> --confirm
```

Or use the Render Dashboard → delete services and databases.

---

## Related

- podfly package: https://github.com/127thousand/podfly  
- Render CLI: https://render.com/docs/cli  
- Render monorepos / `rootDir`: https://render.com/docs/monorepo-support  
- **Serverpod Cloud** (managed, no DIY git/Render): https://serverpod.dev/cloud  
