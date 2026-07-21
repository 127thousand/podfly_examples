# AWS examples

| Example | What it proves |
|---------|----------------|
| [**api_only**](api_only/) | Serverpod API on **App Runner** (Docker → ECR) |
| [**realtime_monolith**](realtime_monolith/) | Flutter web + API in **one** service (nginx monolith). **RPC works; WebSockets do not** (App Runner Envoy 403) |

## Prerequisites

- [AWS CLI](https://docs.aws.amazon.com/cli/) (`aws configure` / SSO)
- Docker (local image build, `linux/amd64`)
- `dart pub global activate podfly`

## Cost note

App Runner bills for provisioned capacity more aggressively than Cloud Run
scale-to-zero. **Delete the service** when the demo is finished.
