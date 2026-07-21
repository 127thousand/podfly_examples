# gcp/api_only

Serverpod **API only** on **Google Cloud Run** (stateless, scale-to-zero).

Cheap path: Cloud Run + optional Neon/Cloud SQL later — **not** GCE Terraform.

```bash
gcloud auth login
gcloud config set project YOUR_PROJECT
gcloud services enable run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com

dart pub global activate podfly
cd gcp/api_only
# set cloud_run.project in podfly.yaml
podfly deploy --api --yes --smoke
```

See Serverpod docs: [Cloud Run console guide](https://docs.serverpod.dev/deployments/deploying-to-gcr-console).
