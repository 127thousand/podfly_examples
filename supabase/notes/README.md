# Supabase Postgres notes (bidirectional smoke)

Flutter web on **Netlify**; Serverpod API on **Fly**; Postgres on **Supabase**.

> **Status (2026-07-23):** Smoke-deployed, hang fixed via session pooler, then **torn down**.  
> No live URLs — redeploy with the commands below.

## Architecture

| Piece | Provider |
|-------|----------|
| UI | Netlify (`podfly-supabase-notes-ui`) |
| API | Fly (`podfly-supabase-notes-api`) |
| Postgres | Supabase session pooler (`aws-0-<region>.pooler.supabase.com`) |

```text
Browser UI → Fly API → Supabase Postgres pooler (INSERT / SELECT)
```

### Why the pooler?

Free-tier direct hosts (`db.<ref>.supabase.co`) are often **IPv6-only** (AAAA, no A).
From Fly (and other IPv4-leaning egress), DB endpoints hang — e.g. browser
`/note/list` never returns while `/greeting/hello` (no DB) still works.

podfly defaults `database.supabase.use_pooler: true` and connects as
`postgres.<project_ref>@aws-0-<region>.pooler.supabase.com` with SSL.

## Deploy

```bash
# needs: fly, netlify login, supabase login, free project slot
cd supabase/notes
podfly deploy --yes --smoke
```

podfly provisions Supabase (if missing), writes `.podfly_supabase_pg.json` (pooler
host + user), patches `production.yaml` / `passwords.yaml`, deploys Fly with
`--apply-migrations`, Netlify UI.

## Prove bidirectional data

```bash
API=https://podfly-supabase-notes-api.fly.dev   # after deploy

curl -sS -X POST "$API/note/count" -H 'Content-Type: application/json' -d '{}'
curl -sS -X POST "$API/note/add" -H 'Content-Type: application/json' \
  -d '{"text":"hello from fly via supabase"}'
curl -sS -X POST "$API/note/list" -H 'Content-Type: application/json' -d '{}'
```

Or use the Netlify UI: add a note, refresh — rows come from Supabase.

**Verified 2026-07-23:** insert → list returns rows → count matches; UI + API.
Re-verified after pooler fix (list/add no longer hang).

### Migration note

Serverpod may log `Invalid date format` / `now()Z` after applying migrations on
Supabase (schema verify). CRUD still works.

## Teardown

```bash
fly apps destroy podfly-supabase-notes-api --yes
netlify sites:delete <site-id> --force   # or: netlify sites:list
supabase projects delete <project_ref> --yes
rm -f notes_server/config/.podfly_supabase_pg.json
# strip production.database from passwords.yaml if present
```

Torn down 2026-07-23: Fly app, Netlify site, Supabase project `podfly-supabase-notes`.

## Related

- [podfly doc/supabase.md](https://github.com/127thousand/podfly/blob/main/doc/supabase.md)
