# aws/ecs_realtime

**ECS Fargate + ALB** monolith: Flutter web + Serverpod API + **WebSocket streams**.

Unlike [App Runner](../realtime_monolith/), ALB forwards `Upgrade: websocket`
(expect **101**, not Envoy 403).

```text
Browser ──HTTP :80──► ALB (idle 3600s, stickiness)
                         └─ target group ──► Fargate task
                                              nginx :8080
                                                ├─ Flutter static
                                                └─ proxy → Serverpod :8081
```

No CDK/Terraform — `podfly` drives the `aws` CLI (ECR, SGs, ALB, task def, service).

## Deploy

```bash
aws configure
docker
dart pub global activate podfly   # need aws_ecs support (podfly ≥ current main)

cd aws/ecs_realtime
podfly deploy --yes --smoke
```

Open the printed ALB URL → **Start clock stream**.

Smoke may need ~1–2 minutes after deploy for ALB DNS + target health.

### WebSocket probe

```bash
curl -i -N \
  -H 'Connection: Upgrade' \
  -H 'Upgrade: websocket' \
  -H 'Sec-WebSocket-Version: 13' \
  -H 'Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==' \
  "http://YOUR_ALB_DNS/v1/websocket"
# expect: HTTP/1.1 101 Switching Protocols
```

## Teardown

```bash
REGION=us-east-1
CLUSTER=podfly-ecs-rt
SERVICE=podfly-ecs-rt

aws ecs update-service --cluster $CLUSTER --service $SERVICE \
  --desired-count 0 --region $REGION
aws ecs delete-service --cluster $CLUSTER --service $SERVICE --force --region $REGION
# wait for tasks to stop, then:
aws elbv2 delete-load-balancer --load-balancer-arn "$ALB_ARN" --region $REGION
# after ALB is gone:
aws elbv2 delete-target-group --target-group-arn "$TG_ARN" --region $REGION
aws ecs delete-cluster --cluster $CLUSTER --region $REGION
aws ecr delete-repository --repository-name podfly-ecs-rt --force --region $REGION
# SGs: podfly-ecs-rt-alb-sg, podfly-ecs-rt-task-sg
# optional: logs delete-log-group /ecs/podfly-ecs-rt
```

ARNs are saved in `podfly.yaml` after deploy (`load_balancer_arn`, `target_group_arn`).

**Cost:** ALB + Fargate have a floor — delete when done.

## See also

- [podfly `host: aws_ecs`](https://github.com/127thousand/podfly/blob/main/doc/aws.md)
- [ECS sketch](https://github.com/127thousand/podfly/blob/main/doc/specs/2026-07-21-aws-ecs-realtime-sketch.md)
- App Runner packaging (no WS): [../realtime_monolith](../realtime_monolith/)
