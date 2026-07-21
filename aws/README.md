# AWS examples

| Example | What it proves |
|---------|----------------|
| [**api_only**](api_only/) | Serverpod API on **App Runner** (Docker → ECR → service) |

## Prerequisites

- [AWS CLI](https://docs.aws.amazon.com/cli/) (`aws configure` / SSO)
- Docker (local image build)
- `dart pub global activate podfly`

## Cost note

App Runner bills for provisioned capacity more aggressively than Cloud Run
scale-to-zero. **Delete the service** when the demo is finished (see example README).
