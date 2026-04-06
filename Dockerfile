FROM cloudflare/cloudflared:latest
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 CMD ["cloudflared", "tunnel", "ready"]
