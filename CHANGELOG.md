# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project uses [Calendar Versioning](https://calver.org/) (`YYYY.MM.DD`)
because it is a continuously delivered collection of templates rather than a
semantically versioned API. Each release ships a signed source archive with a
SLSA build-provenance attestation — see [`VERIFICATION.md`](VERIFICATION.md).

## [Unreleased]

### Added
- Weekly auto-tag workflow (`.github/workflows/weekly-release.yml`): runs every
  Tuesday at 08:00 UTC, tags `vYYYY.MM.DD` when commits exist since the last
  release, then dispatches `release.yml` to publish the signed artifacts.

### Changed
- `release.yml` now also accepts `workflow_dispatch` so the auto-tag job can
  chain into it (GitHub suppresses workflow triggers from `GITHUB_TOKEN`
  pushes). Job is gated to `refs/tags/v*` so accidental dispatches against
  `main` are no-ops.

### Verified
Pre-flight upgrade testing for the major/minor bumps queued in Renovate
(Dependency Dashboard, #2). Each DB upgrade was booted with the current
image, seeded with test data in an isolated environment, stopped, then
restarted on the new tag with the same data dir, and verified end-to-end.
All passed with zero error/fatal/panic lines in container logs.

- `mongo 8.0.23 → 8.3.2` (used by `meshcentral`): data dir survives,
  SCRAM-SHA-256 credentials preserved, seeded docs readable post-upgrade,
  `db.version()` reports 8.3.2.
- `mariadb 11.8.6 → 12.2.2` (used by `uptime-kuma`): data dir survives,
  `mariadb-upgrade` runs cleanly (all 8 phases OK), seeded rows readable,
  `VERSION()` reports 12.2.2.
- `redis 7.4.9-alpine3.21 → 8.0.6-alpine3.21` (used by `nextcloud` and
  `zulip`): AUTH preserved, AOF + RDB persistence both survive, string /
  integer / list keys readable, `redis_version: 8.0.6`.
- `rabbitmq 4.2.5-alpine → 4.3.0-alpine` (used by `stoat` and `zulip`):
  Mnesia DB survives, vhosts and user tags preserved, `RabbitMQ version:
  4.3.0`. Required pairing with the hostname fix below to be safe across
  container recreation.
- `stoatchat v0.12.1 → v0.13.6` (8-service set, used by `stoat`): all 8
  image tags pull, Dockerfile-level config identical (entrypoint, env,
  labels), binary boots cleanly reporting `revolt-delta@0.13.6`.
- `actions/upload-artifact v4.6.2 → v7.0.1`, `dawidd6/action-download-artifact
  v6 → v21`, `peter-evans/create-pull-request v7.0.11 → v8.1.1`: changelog
  review only; our inputs unchanged across all version jumps. No workflow
  edits required.

### Fixed
- **rabbitmq hostname stability** in `zulip/docker-compose.yml` and
  `stoat/docker-compose.yml`. Neither template previously set `hostname:`
  on the rabbitmq service. RabbitMQ stores Mnesia data under
  `mnesia/rabbit@<container-hostname>/`; any container recreation (image
  bump, env change, manual `--force-recreate`) got a new random hostname
  and started as a fresh "virgin node", orphaning the old node's data on
  disk. Now sets `hostname: rabbitmq` (zulip) / `hostname: rabbit` (stoat)
  to lock the Erlang node name across recreations. Verified end-to-end:
  vhosts and user tags survive `--force-recreate`, and the Mnesia dir
  contains only the expected `rabbit@<stable-hostname>/` directory.

  **Migration note for existing deployers**: if you already have a
  running deployment of either stack, you must rename your existing
  Mnesia directory before the next container restart. Find the current
  node directory (e.g. `./data/rabbit/mnesia/rabbit@<some-random-id>/`)
  and rename it to `rabbit@rabbitmq/` (zulip) or `rabbit@rabbit/` (stoat),
  then do the same rename inside `mnesia/rabbit@<some-random-id>-feature_flags`
  and `mnesia/rabbit@<some-random-id>-plugins-expand`. Without this
  rename the container will start fresh and existing vhosts / users /
  queues will be unreachable. Fresh deployments are unaffected.

## [2026.05.21] — Initial signed release

First tagged, signed snapshot of the docker-compose template collection. This
release establishes the project's public release process: every tag now ships
with cosign-signed checksums and a SLSA build-provenance attestation.

### Added
- `CHANGELOG.md` (this file) and `VERIFICATION.md` covering artifact verification.
- `CONTRIBUTING.md` and `CODE_OF_CONDUCT.md` (Contributor Covenant 2.1).
- `SECURITY.md` with private-advisory reporting flow.
- `AUDIT.md` weekly Trivy CVE snapshot, refreshed by `weekly-audit.yml`.
- Renovate dependency automation (`renovate.json`).
- CI hardening: OpenSSF Scorecard, Trivy misconfig scan on PRs, `actionlint`,
  PR-time CVE gate (`scan` required check on `main`).
- SHA-pinned, least-privilege GitHub Actions across every workflow.
- Trivy installer pinned by SHA256 checksum in CI and weekly audit.
- Stacks: authentik, baserow, docuseal, freshrss, jellyfin, meshcentral, n8n,
  navidrome, nextcloud (vanilla 5-service), openwebui, qbittorrent, serpbear,
  uptime-kuma, wg-adguard, zulip, and a Dockhand management stack.

### Changed
- Replaced LSIO/Docker Hardened third-party rebuilds with official upstream
  images where security-critical (e.g. mongo, postgres, redis).
- Hardened every stack to a minimum-capabilities baseline (most are zero-cap).
- Replaced `nextcloud-aio` with a vanilla 5-service Nextcloud template.

### Removed
- `portainer-ce`, `portainer-agent`, `watchtower`, and `nginx-proxy-manager`
  templates (superseded by Dockhand / Caddy / Pangolin).
- Redundant Redis service from authentik (bundled upstream since 2025.10).
- `com.centurylinklabs.watchtower.enable` labels across all stacks.

### Security
- `main` branch protection requires the `scan` CVE gate; `enforce_admins`
  enabled so the rule has no bypass.
- Workflow tokens scoped to `contents: read` by default, with `write` granted
  only at job level where strictly required (publishing PRs, releases).
- Branch isolation for PR scripts and Trivy installer to mitigate supply-chain
  risk from forked PRs.

[Unreleased]: https://github.com/wnstify/docker/compare/v2026.05.21...HEAD
[2026.05.21]: https://github.com/wnstify/docker/releases/tag/v2026.05.21
