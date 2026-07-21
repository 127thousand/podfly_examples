# aws/ecs_realtime

**ECS Fargate + ALB** monolith: Flutter web + Serverpod API + **WebSocket streams**.

Unlike App Runner, ALB forwards `Upgrade: websocket` (expect **101**, not Envoy 403).

```text
Browser ──HTTP :80──► ALB (idle 3600s)
                         └─ target group ──► Fargate task
                                              nginx :8080
                                                ├─ Flutter static
                                                └─ proxy → Serverpod :8081
```

Same container layout as [../realtime_monolith](../realtime_monolith/) (App Runner packaging demo).

## Deploy

```bash
aws configure
docker
dart pub global activate podfly   # or path to local podfly with aws_ecs

cd aws/ecs_realtime
podfly deploy --yes --smoke
```

Open the ALB URL → **Start clock stream**.

### WebSocket probe

```bash
curl -i -N \
  -H 'Connection: Upgrade' \
  -H 'Upgrade: websocket' \
  -H 'Sec-WebSocket-Version: 13' \
  -H 'Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==' \
  "http://YOUR_ALB/v1/websocket"
# expect: 101 Switching Protocols
```

## Teardown

```bash
# From saved arns in podfly.yaml or console:
aws ecs update-service --cluster podfly-ecs-rt --service podfly-ecs-rt --desired-count 0 --region us-east-1
aws ecs delete-service --cluster podfly-ecs-rt --service podfly-ecs-rt --force --region us-east-1
aws elbv2 delete-load-balancer --load-balancer-arn "$ALB_ARN" --region us-east-1
# then delete target group, SGs, ECR repo, cluster as needed
```

**Cost:** ALB + Fargate have a floor — delete when done.
