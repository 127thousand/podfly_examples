# Google Cloud Run examples

Cheap serverless Serverpod on **Cloud Run** (not GCE / Terraform).

| Example | What it proves |
|---------|----------------|
| [**api_only**](api_only/) | Stateless API: `gcloud run deploy --source`, scale-to-zero |
| [**realtime_monolith**](realtime_monolith/) | Flutter web + API + **WebSocket streams** in **one** service |

## Monolith shape

Cloud Run exposes **one public port**. The realtime example uses nginx in the container:

```text
Browser ──HTTPS :8080──► nginx
                           ├─ static  → Flutter web
                           └─ API/WS  → Serverpod :8081
```

## Prerequisites

```bash
gcloud auth login
gcloud config set project YOUR_GCP_PROJECT
# First time: enable APIs + Cloud Build SA roles (storage/build)
dart pub global activate podfly
```

## Deploy / teardown

```bash
cd api_only   # or realtime_monolith
# set cloud_run.project in podfly.yaml
podfly deploy --yes --smoke

gcloud run services delete SERVICE --region us-central1 --quiet
```

Scale-to-zero (`min_instances: 0`) costs near nothing when idle; **delete the service** when the demo is done so revisions and accidental traffic do not surprise you.
