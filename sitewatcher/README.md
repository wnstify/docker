# SiteWatcher

SiteWatcher tracks website uptime and response times and alerts you when a TLS
certificate or domain registration is close to expiry.

## Setup

```sh
cp .env.example .env
docker compose run --rm web sitewatcher setup
docker compose up -d --wait
```

Choose the first owner's username and password when prompted, then sign in at
http://127.0.0.1:8080/. Change `SITEWATCHER_PORT` in `.env` if that port is
in use. There are no required environment secrets or external Docker networks.

## Deployment notes

- Only the web service publishes a port, and it binds to loopback. Follow the
  [upstream reverse-proxy guide](https://github.com/NikKurkov/sitewatcher/blob/main/docs/usage.en.md)
  before allowing remote access.
- Both services run as the image's unprivileged user with all capabilities
  dropped. The worker needs outbound access to check monitored websites.
- The services share SQLite and settings in the named `sitewatcher-data` volume.
  Keep this volume when stopping or upgrading. Stop the stack before taking a
  filesystem copy of the volume.
- Both services have a 256 MiB memory limit. Raise it if your number of checks
  requires it. `/healthz` checks web readiness. The worker's check confirms that
  its process is running.

[Source](https://github.com/NikKurkov/sitewatcher) ·
[Container image](https://github.com/users/NikKurkov/packages/container/package/sitewatcher)
