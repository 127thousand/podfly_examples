# hetzner/api_only

Stateless **Serverpod API** on a **Hetzner Cloud VPS** (Docker over SSH + Caddy HTTPS).

Hetzner does **not** give a product FQDN. You get a public **IPv4**, reverse DNS
(`static.…clients.your-server.de`), or your own domain. podfly installs **Caddy**
on **:443** → container **:8080**.

## Prerequisites

```bash
brew install hcloud
hcloud context create podfly
hcloud ssh-key create --name mac --public-key-from-file ~/.ssh/id_ed25519.pub
docker
dart pub global activate podfly
```

## Deploy

```bash
cd hetzner/api_only
podfly deploy --api --yes --smoke
```

Open the printed `https://…` URL.

## Config knobs

| Key | Meaning |
|-----|---------|
| `create: true` | Auto-create if unbound (`--yes`) |
| `location` / `server_type` | Preferences (live API validates) |
| `https: true` | Caddy + Let's Encrypt on 443 (default) |
| `domain` | Custom hostname (A → IP); else PTR |

## Teardown

```bash
hcloud server delete <name-or-id>
```

**Cost:** VPS bills hourly — delete when done.

## See also

- [realtime_monolith](../realtime_monolith/) — Flutter + WebSocket streams  
- [podfly doc/hetzner.md](https://github.com/127thousand/podfly/blob/main/doc/hetzner.md)
