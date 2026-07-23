# DigitalOcean API-only

```bash
dart pub global activate podfly
cd digitalocean/api_only
podfly deploy --api --yes --smoke
```

Requires Docker + DOCR (`ben-registry`). See [../README.md](../README.md).
