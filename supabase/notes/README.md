# Supabase Postgres notes (bidirectional smoke)

Flutter web on **Netlify**; Serverpod API on **Fly**; Postgres on **Supabase**.

> **Live demo (re-verified 2026-07-23):** UI + API + Supabase write/read working.  
> Tear down when done (commands below).

## Architecture

| Piece | Provider |
|-------|----------|
| UI | Netlify (`podfly-supabase-notes-ui`) |
| API | Fly (`podfly-supabase-notes-api`) |
| Postgres | Supabase (`podfly-supabase-notes`) |

```text
Browser UI → Fly API → Supabase Postgres (INSERT / SELECT)
```

## Deploy

```bash
# needs: fly, netlify login, supabase login, free project slot
cd supabase/notes
podfly deploy --yes --smoke
```

podfly provisions Supabase (if missing), writes `.podfly_supabase_pg.json`, patches
`production.yaml` / `passwords.yaml`, deploys Fly with `--apply-migrations`, Netlify UI.

## Prove bidirectional data

```bash
API=https://podfly-supabase-notes-api.fly.dev   # after deploy

curl -sS -X POST "$API/note/count" -H 'Content-Type: application/json' -d '{}'
curl -sS -X POST "$API/note/add" -H 'Content-Type: application/json' \
  -d '{"text":"hello from fly via supabase"}'
curl -sS -X POST "$API/note/list" -H 'Content-Type: application/json' -d '{}'
```

Or use the Netlify UI: add a note, refresh — rows come from Supabase.

**Verified:** count `0` → insert → list returns rows → count matches. UI + API both exercised.

### Migration note

Serverpod may log `Invalid date format` / `now()Z` after applying migrations on Supabase (schema verify). CRUD still works.

## Teardown

```bash
fly apps destroy podfly-supabase-notes-api --yes
netlify sites:delete <site-id> --force
supabase projects delete <project_ref> --yes
rm -f notes_server/config/.podfly_supabase_pg.json
```

Torn down 2026-07-23: Fly app, Netlify site, Supabase project `podfly-supabase-notes`.

## Related

- [podfly doc/supabase.md](https://github.com/127thousand/podfly/blob/main/doc/supabase.md)
