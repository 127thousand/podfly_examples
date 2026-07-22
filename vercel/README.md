# Vercel examples

Static Flutter web via **`web_host: vercel`** (same role as Cloudflare Pages).

| Path | API | UI | Streams |
|------|-----|-----|---------|
| [split_fly](split_fly/) | Fly.io | Vercel | — |
| [realtime_split](realtime_split/) | Fly.io | Vercel | ✅ WS → Fly |

API + WebSockets never run on Vercel — only the Flutter web build. Streams
use the API host (`SERVER_URL` / Fly).
