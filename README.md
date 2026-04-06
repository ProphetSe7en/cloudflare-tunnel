# cloudflared

Minimal wrapper around the official [`cloudflare/cloudflared`](https://hub.docker.com/r/cloudflare/cloudflared) image that adds a Docker healthcheck.

## Why?

The official cloudflared image uses a [distroless](https://github.com/GoogleContainerTools/distroless) base with no shell (`/bin/sh`). Docker's `--health-cmd` parameter always runs commands through `/bin/sh`, which means healthchecks added via Docker CLI, Unraid Extra Parameters, or Docker Compose `healthcheck.test` strings will always fail with:

```
exec: "/bin/sh": stat /bin/sh: no such file or directory
```

The only way to use exec-form healthchecks (which bypass the shell) is via a `HEALTHCHECK CMD` instruction in a Dockerfile. This image does exactly that — nothing more.

## What this image does

```dockerfile
FROM cloudflare/cloudflared:latest
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 CMD ["cloudflared", "tunnel", "ready"]
```

That's the entire Dockerfile. It inherits everything from the official image and adds a healthcheck using `cloudflared tunnel ready` — the built-in readiness command that checks if the tunnel has active connections.

## Requirements

You must enable the metrics server for `cloudflared tunnel ready` to work. Add this environment variable to your container:

```
TUNNEL_METRICS=0.0.0.0:60123
```

The port number (60123) can be anything — it's only used internally by the container. Without this variable, the ready command has no endpoint to query and the healthcheck will always fail.

## Getting your tunnel token

1. Log in to the [Cloudflare Zero Trust dashboard](https://dash.teams.cloudflare.com)
2. Go to **Networks > Tunnels > Create a tunnel**
3. Select **Cloudflared** as the connector type
4. Give your tunnel a name (e.g. `unraid`, `homelab`)
5. Choose **Docker** as the environment
6. Cloudflare displays a `docker run` command — copy the token (the long string after `--token`)
7. Configure your tunnel's public hostnames (which services to expose) in the Cloudflare dashboard

## Usage

### Docker run

```bash
docker run -d \
  --name cloudflared \
  -e TUNNEL_METRICS=0.0.0.0:60123 \
  ghcr.io/prophetse7en/cloudflared:latest \
  tunnel --no-autoupdate run --token <your-token>
```

### Docker Compose

```yaml
services:
  cloudflared:
    image: ghcr.io/prophetse7en/cloudflared:latest
    environment:
      - TUNNEL_METRICS=0.0.0.0:60123
    command: tunnel --no-autoupdate run --token <your-token>
    restart: unless-stopped
```

### Unraid

Use `ghcr.io/prophetse7en/cloudflared:latest` as the Repository in your container template. Add `TUNNEL_METRICS` as a variable with value `0.0.0.0:60123`. No Extra Parameters needed — the healthcheck is built into the image.

## Updates

This image is rebuilt automatically every week to track the latest upstream `cloudflare/cloudflared` release. The healthcheck configuration is the only addition.

## Verify

You can inspect the image to confirm only a healthcheck was added:

```bash
docker inspect ghcr.io/prophetse7en/cloudflared:latest --format '{{json .Config.Healthcheck}}'
```

Expected output:
```json
{"Test":["CMD","cloudflared","tunnel","ready"],"Interval":30000000000,"Timeout":5000000000,"StartPeriod":10000000000,"Retries":3}
```
