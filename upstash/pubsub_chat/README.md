# Upstash Redis PubSub chat

Flutter web on **Netlify**; Serverpod API on **Fly** (HA, 2 machines); **Upstash Redis** for global server messages.

> **Live demo:** torn down after a successful multi-machine PubSub proof (2026-07-22).  
> Re-deploy locally with the steps below — nothing is left running in cloud accounts.

## Why this example

Two browsers both receiving chat is **not** enough to prove multi-instance PubSub — both tabs can stick to the same Fly machine.

This demo makes the proof explicit:

| UI chip | Meaning |
|---------|---------|
| **This tab WS** | Fly machine owning this browser’s sticky WebSocket (`kind: hello` on connect) |
| **Last HTTP send/whoami** | Machine that handled the last RPC (load-balanced independently of WS) |
| **Cross-machine hits** | Chat lines where `send machine ≠ this tab’s WS machine` |

A green **CROSS-MACHINE** line means: published on machine A, delivered to a WebSocket on machine B → Redis (`postMessage(..., global: true)`), not in-process memory.

```text
Browser A ──WSS──► Fly machine 1 ──listen──► createStream(channel)
Browser B ──WSS──► Fly machine 2 ──listen──► createStream(channel)
Browser A ──HTTP POST send──► machine 1 or 2
                              │
                              ▼ postMessage(global: true)
                         Upstash Redis PubSub
                              │
              ┌───────────────┴───────────────┐
              ▼                               ▼
         machine 1 stream                machine 2 stream
```

## Architecture

| Piece | Provider | Role |
|-------|----------|------|
| API | Fly (`podfly-upstash-chat-api`) | Serverpod, 2 machines, WebSockets |
| UI | Netlify (`podfly-upstash-chat-ui`) | Flutter web static; `SERVER_URL` → Fly |
| Redis | Upstash (`podfly-chat-redis`) | Cross-instance messages |

Server endpoint (sketch):

```dart
Stream<ChatMessage> listen(Session session) async* {
  yield ChatMessage(/* kind: hello, serverId: FLY_MACHINE_ID */);
  yield* session.messages.createStream<ChatMessage>('podfly_chat');
}

Future<ChatMessage> send(Session session, String author, String text) async {
  final msg = ChatMessage(/* serverId: FLY_MACHINE_ID, kind: chat */);
  await session.messages.postMessage('podfly_chat', msg, global: true);
  return msg;
}
```

`serverId` uses the last 6 characters of `FLY_MACHINE_ID` so HA demos show which instance handled each event.

## Prerequisites

```bash
# CLIs
dart pub global activate podfly   # or path activate from the podfly repo
fly auth login
netlify login
npm i -g @upstash/cli && upstash login
```

## Deploy

```bash
cd upstash/pubsub_chat
podfly deploy --yes --smoke
```

podfly will:

1. Create Fly app (HA / `min_machines_running = 2`)
2. Provision Upstash Redis, patch `production.yaml` + `passwords.yaml`, set Fly `SERVERPOD_REDIS_*` + `SERVERPOD_PASSWORD_redis`
3. Build Flutter web with `SERVER_URL=https://…fly.dev/`
4. Deploy Netlify site + Fly image
5. Smoke-check greeting API + UI `/`

## How to test (2 browsers)

1. Open the Netlify UI in two windows (normal + private is fine).
2. Note each tab’s **This tab WS**. Use **Reconnect WS** until they differ (optional).
3. Spam **Send** — HTTP often lands on the other machine.
4. When a line is green / **Cross-machine hits ≥ 1**, multi-instance PubSub is proven.

Without Redis, `global: true` fails or never reaches the other instance.

## Teardown

```bash
# Fly API (both machines)
fly apps destroy podfly-upstash-chat-api --yes

# Netlify UI
netlify sites:list
netlify sites:delete <site-id> --force
# or by name after listing ids:
# netlify sites:delete $(netlify sites:list --json | jq -r '.[]|select(.name=="podfly-upstash-chat-ui")|.id') --force

# Upstash Redis
upstash redis list
upstash redis delete --db-id <id>

# Local secrets written by podfly (do not commit)
rm -f chat_server/config/.podfly_upstash_redis.json
# passwords.yaml is gitignored; strip production.redis if present
```

### What was torn down (reference deploy)

| Resource | Name / id | Status |
|----------|-----------|--------|
| Fly app | `podfly-upstash-chat-api` | destroyed |
| Netlify site | `podfly-upstash-chat-ui` (`e70ca608-…`) | deleted |
| Upstash Redis | `podfly-chat-redis` (`3390b755-…`) | deleted |

## Related

- [podfly doc/upstash.md](https://github.com/127thousand/podfly/blob/main/doc/upstash.md)
- [Serverpod server events](https://docs.serverpod.dev/concepts/streams) / messages + Redis
- Sibling examples: [netlify/realtime_split](../../netlify/realtime_split/) (WS without Redis)
