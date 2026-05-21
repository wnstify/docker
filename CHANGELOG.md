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
