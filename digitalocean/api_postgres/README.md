# DigitalOcean API + Managed Postgres

```bash
dart pub global activate podfly
cd digitalocean/api_postgres
podfly deploy --api --yes --smoke
```

Requires Docker + DOCR. Managed Postgres is billable — tear down when done. See [../README.md](../README.md).
