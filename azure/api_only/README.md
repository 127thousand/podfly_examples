# azure/api_only

Stateless **Serverpod API** on **Azure Container Apps** (ACR image).

## Prerequisites

```bash
az login
# az account set --subscription <id>   # if multiple
docker                 # local build → ACR
dart pub global activate podfly
# az extension add --name containerapp   # if missing
```

podfly creates (when missing):

- resource group (`{app}-rg`)
- ACR Basic with admin user (for pull credentials)
- Container Apps environment
- container app with external HTTPS ingress

## Deploy

```bash
cd azure/api_only
# edit azure.location in podfly.yaml if needed
podfly deploy --api --yes --smoke
```

## Teardown (stop charges)

Container Apps + ACR bill while they exist. Easiest: delete the resource group
saved in `podfly.yaml` after deploy:

```bash
az group delete --name "$RESOURCE_GROUP" --yes --no-wait
```

## Notes

- Image is built for **`linux/amd64`**.
- Scale-to-zero when `min_replicas: 0` (default).
- WebSockets are supported on Container Apps (unlike AWS App Runner).
- Postgres: use Neon later (`database.provider: neon`); Azure Database for PostgreSQL is out of scope for this cheap demo.
