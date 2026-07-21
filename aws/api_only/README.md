# aws/api_only

Stateless **Serverpod API** on **AWS App Runner** (ECR image).

## Prerequisites

```bash
aws configure          # or SSO
docker                 # local build → ECR
dart pub global activate podfly
```

IAM: podfly creates `AppRunnerECRAccessRole` (if missing) with
`AWSAppRunnerServicePolicyForECRAccess` so App Runner can pull private ECR.

## Deploy

```bash
cd aws/api_only
# edit aws.region in podfly.yaml if needed
podfly deploy --api --yes --smoke
```

## Teardown (stop charges)

App Runner is **not** free scale-to-zero like Cloud Run. Delete when done:

```bash
# service arn is saved in podfly.yaml after deploy
aws apprunner delete-service --service-arn "$SERVICE_ARN" --region us-east-1

# optional: remove ECR images/repo
aws ecr delete-repository --repository-name podfly-aws-api-only --region us-east-1 --force

# optional: keep or delete AppRunnerECRAccessRole (shared)
```

## Notes

- Image is built for **`linux/amd64`** (App Runner).
- Dockerfile ships `/app/entrypoint.sh`; podfly sets App Runner **`start_command`**
  (CREATE often fails silently if you rely only on a shell-form `ENTRYPOINT`).
- TCP health checks (no dependency on a custom HTTP path).
- Postgres: use Neon later (`database.provider: neon`); RDS is out of scope for this cheap demo.

