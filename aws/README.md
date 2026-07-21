# AWS examples

| Example | What it proves |
|---------|----------------|
| [**api_only**](api_only/) | Serverpod API on **App Runner** (Docker → ECR) |
| [**realtime_monolith**](realtime_monolith/) | Flutter web + API on App Runner. **RPC works; WebSockets do not** |
| [**ecs_realtime**](ecs_realtime/) | Flutter web + API + **WebSocket streams** on **ECS Fargate + ALB** |

## WebSockets on AWS

**App Runner does not support WebSockets.** The managed edge (Envoy) returns
**HTTP 403** on `Upgrade: websocket` before the container. Envoy *can* do WS in
general, but App Runner does not expose Envoy config (no customer toggle).

| Path | RPC | Streams (WS) |
|------|-----|----------------|
| App Runner (`host: aws`) | ✅ | ❌ |
| Cloud Run | ✅ | ✅ (`gcp/realtime_monolith`) |
| **ECS Fargate + ALB** (`host: aws_ecs`) | ✅ | ✅ (`ecs_realtime`) |

Full write-up: [podfly `doc/aws.md`](https://github.com/127thousand/podfly/blob/main/doc/aws.md).

## Prerequisites

- [AWS CLI](https://docs.aws.amazon.com/cli/) (`aws configure` / SSO)
- Docker (local image build, `linux/amd64`)
- `dart pub global activate podfly`

## Cost note

App Runner bills for provisioned capacity more aggressively than Cloud Run
scale-to-zero. **Delete the service** when the demo is finished.
