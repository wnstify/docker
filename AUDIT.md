# Container Image Security Audit

| Field | Value |
|---|---|
| **Scan date** | 2026-06-01 |
| **Scanner** | Trivy 0.70.0 |
| **Vulnerability DB** | aquasec/trivy-db v2 — updated 2026-06-01 01:09:32 UTC |
| **Scope** | Every image referenced in every `docker-compose.yml` in this repo (43 images, 17 templates) |
| **Severities reported** | Critical / High / Medium / Low (Info, Negligible, and Unknown omitted as requested) |

## Methodology

Each image was scanned with:
```
trivy image --severity CRITICAL,HIGH,MEDIUM,LOW \
  --scanners vuln --no-progress --skip-db-update \
  --format json --timeout 15m <image>
```

Findings are then triaged against **the actual hardened configuration in this repo** — meaning a CVE in a library bundled in an image only matters if (a) the running container can reach a code path that touches it, AND (b) it is not already neutered by the compose's `cap_drop: ALL`, `no-new-privileges`, internal-only Docker networks, `127.0.0.1` port binding, or reverse-proxy fronting. Vulnerabilities that pass that filter are listed in "Notable Findings". Vulnerabilities that fail it are summarized in [Filtered noise](#filtered-noise) so you can see what was deliberately deprioritised and why.

Each notable finding gets a tag:

- `[ACTION]` — patch / upgrade / change config now
- `[WATCH]` — track upstream; no clean fix yet, but mitigated
- `[CONDITIONAL]` — exploitable only if you enable a specific feature
- `[NOISE]` — listed for completeness; not exploitable in this repo's config

## Executive Summary

Severity counts are aggregated across all images in each template (e.g. `nextcloud` = nextcloud + postgres + redis + nginx). The `Verdict` column reflects production risk in **this** hardened configuration, not raw Trivy severity.

| Template | Crit | High | Med | Low | Verdict |
|---|---:|---:|---:|---:|---|
| **uptime-kuma** | 166 | 321 | 476 | 303 | **ACTION** — bundled Chromium has ~150 critical CVEs; only relevant if you enable URL screenshot / keyword monitors |
| **openwebui** | 30 | 259 | 1069 | 801 | **WATCH** — mostly OS-library noise (Mesa, FFmpeg, mbedTLS) in a ~6.7 GB ML image; few are reachable |
| **authentik** | 12 | 125 | 422 | 318 | **WATCH** — 11 of the 12 criticals are in `authentik-server`'s bundled OpenSSL/GnuTLS/Go stdlib; not reachable through normal auth paths |
| **baserow** | 10 | 117 | 271 | 280 | WATCH — bundled `smallstep/certificates` SCEP RCE not exposed; rest is OS-lib noise |
| **n8n** | 6 | 46 | 95 | 117 | **ACTION** — 5 of 6 criticals are n8n's own code (prototype-pollution → RCE, vm2 sandbox escape, file read). See per-template detail. |
| **stoat** | 6 | 99 | 183 | 100 | CONDITIONAL — split between livekit Go-stdlib DoS and base-image OpenSSL noise |
| **docuseal** | 4 | 32 | 78 | 116 | CONDITIONAL — net-imap CRLF injection only fires if you configure inbound IMAP |
| **navidrome** | 4 | 21 | 9 | 4 | NOISE — Alpine OpenSSL/GnuTLS criticals are 32-bit / DTLS / unauth-CMS paths none of which Navidrome exercises |
| **dockhand** | 5 | 41 | 70 | 3 | CONDITIONAL — BuildKit untrusted-frontend RCE only fires if you build third-party Compose files |
| **zulip** | 3 | 206 | 1677 | 249 | CONDITIONAL — LiteLLM SQL injection only fires if you enable the LLM-bot integration |
| **meshcentral** | 2 | 64 | 85 | 5 | **ACTION** — Handlebars RCE via crafted template AST; review whether your MeshCentral version still ships the affected helper |
| **serpbear** | 2 | 27 | 39 | 5 | NOISE — both criticals are 32-bit-only OpenSSL; you run amd64 |
| **nextcloud** | 1 | 34 | 92 | 115 | NOISE — single critical is Go-stdlib in postgres exporter; libpq "criticals" are server-side CVEs against a client-only library |
| **freshrss** | 0 | 7 | 11 | 0 | NOISE — all 7 "highs" are libpq matched against PostgreSQL **server** CVEs |
| **jellyfin** | 0 | 0 | 34 | 8 | clean — no critical or high |
| **qbittorrent** | 0 | 0 | 14 | 0 | clean — no critical or high |
| **wg-adguard** | 0 | 1 | 6 | 0 | clean — the single high is a `picomatch` ReDoS in wg-easy's build deps, not runtime |

### Templates with zero non-noise findings

`jellyfin`, `qbittorrent`, `wg-adguard`, `freshrss`, `nextcloud`, `serpbear`, `navidrome`, `stoat` (excluding livekit) — these have either no findings, or all findings collapsed to `[NOISE]` for the reasons documented below.

### Clean images (zero CVE at any severity reported)

`adguard/adguardhome:v0.107.75`, `alpine:3.22.4`, `dxflrs/garage:v2.3.0`, `memcached:1.6.42-alpine3.23`, `nginx:1.30.1-alpine3.23`, `rabbitmq:4.2.5-alpine`, `redis:8.6.3-alpine`, `redis:7.4.9-alpine3.21` — these are perfectly clean as of the scan date.

---

## Per-Template Findings

The detail sections below cover only templates where at least one finding survived triage as `[ACTION]`, `[WATCH]` or `[CONDITIONAL]`. Skipped templates are listed under "Templates with zero non-noise findings" above.

---

### n8n — **ACTION**

| Image | Pinned tag | C | H | M | L |
|---|---|---:|---:|---:|---:|
| `docker.n8n.io/n8nio/n8n` | `2.21.4` | 5 | 12 | 14 | 2 |
| `n8nio/runners` | `2.21.4` | 0 | 8 | 7 | 0 |
| `postgres` | `18.4` | 1 | 26 | 74 | 115 |
| `redis` | `7.4.9-alpine3.21` | 0 | 0 | 0 | 0 |

**Notable findings (n8n itself, not its base image):**

| CVE | Component | Title | Tag |
|---|---|---|---|
| CVE-2026-44789 | n8n | HTTP Request Node pagination — prototype pollution → **RCE** | **ACTION** |
| CVE-2026-44790 | n8n | Git Node arbitrary file read | **ACTION** |
| CVE-2026-44791 | n8n | XML Node prototype pollution (patch bypass) | **ACTION** |
| CVE-2026-44990 | `sanitize-html` | Default XSS via `xmp` raw-text passthrough | WATCH |
| CVE-2026-45411 | `vm2` | Async-generator sandbox breakout | **ACTION** |

**Production impact.** n8n's worth in your stack is that workflows execute attacker-supplied templates and HTTP responses — exactly the path these CVEs target. The compose's `cap_drop: ALL` + `no-new-privileges` reduces the blast radius of a sandbox-escape but does not prevent it: the container is on the same `n8n-front` network as your other services, and a compromise lets the attacker pivot to that network. The vm2 + prototype-pollution chain is well-known-exploitable. **Upgrade to the newest n8n release as soon as one is published that addresses these IDs, and consider re-architecting any workflow that consumes untrusted HTTP / Git / XML inputs.**

The 1 critical in `postgres:18.4` is a Go stdlib TLS-resumption issue (CVE-2025-68121) in postgres's metric exporter — `[NOISE]`: postgres is on the `--internal` `n8n-db` network and doesn't terminate TLS for clients.

---

### meshcentral — **ACTION**

| Image | Pinned tag | C | H | M | L |
|---|---|---:|---:|---:|---:|
| `ghcr.io/ylianst/meshcentral` | `1.1.59-mongodb` | 1 | 11 | 24 | 1 |
| `mongo` | `8.0.23` | 1 | 53 | 61 | 4 |

**Notable findings:**

| CVE | Component | Title | Tag |
|---|---|---|---|
| CVE-2026-33937 | `handlebars` | Remote Code Execution via crafted AST object in `compile()` | **ACTION** |

**Production impact.** MeshCentral renders templates server-side; any user-controlled template input is a foothold. The mongo container's 1 critical and 53 highs are Go-stdlib DoS variants (CVE-2025-58183, -61726, -61728, -61729, -32280, etc.) which are real but mongo is on an internal Docker network behind authentication — `[WATCH]` not `[ACTION]`. The handlebars CVE on the meshcentral image is the only one to act on. **Track MeshCentral upstream for a patched 1.1.x release.**

---

### uptime-kuma — **ACTION**

| Image | Pinned tag | C | H | M | L |
|---|---|---:|---:|---:|---:|
| `louislam/uptime-kuma` | `2.3.2` | 165 | 308 | 439 | 295 |
| `mariadb` | `11.8.6` | 1 | 13 | 37 | 8 |

**Notable findings:** Of the 165 critical CVEs in uptime-kuma, roughly **150** are in the bundled `chromium` + `chromium-common` packages (CVE-2026-7333, -7342, -7343, -7344, -7347, -7350, -7352, -7354, -7356, ...). Chromium is bundled so that uptime-kuma's "URL screenshot" / "keyword content" monitor can render pages.

**Production impact.**

- **If you only use ping/HTTP/port/keyword monitors against your own services:** Chromium never launches. The 150+ Chromium CVEs are `[NOISE]` in your config. The mariadb container is on the same Docker network as uptime-kuma (no other access), is reverse-proxied via Caddy (you don't expose it), and its 1 critical is the same Go-stdlib TLS-resumption issue noted elsewhere — `[NOISE]`.
- **If you use "page render" or "browser-based" monitors against arbitrary URLs:** every one of those Chromium CVEs becomes `[ACTION]`. Uptime-kuma upstream releases Chromium patches on a slower cadence than chrome itself; a 6-month-old uptime-kuma routinely ships a Chromium several major versions behind. **Disable browser-based monitors, or run a separate hardened container for them.**

The remaining ~15 non-Chromium criticals are: `protobufjs` injection (CVE-2026-41242), `fast-xml-parser` XSS (CVE-2026-25896), `gnutls` auth-bypass (CVE-2026-42010), gRPC-Go authz bypass (CVE-2026-33186). None are reachable through uptime-kuma's normal monitor types. `[NOISE]` in your config.

---

### authentik — WATCH

| Image | Pinned tag | C | H | M | L |
|---|---|---:|---:|---:|---:|
| `ghcr.io/goauthentik/server` | `2026.2.3` | 11 | 99 | 348 | 203 |
| `postgres` | `18.4` | 1 | 26 | 74 | 115 |

**Notable findings:**

| CVE | Component | Title | Tag |
|---|---|---|---|
| CVE-2025-15467 | openssl | CMS parsing oversized IV → RCE/DoS | NOISE (authentik does not parse CMS) |
| CVE-2026-31789 | openssl | 32-bit X.509 heap overflow | NOISE (amd64 only) |
| CVE-2026-33186 | grpc-go | HTTP/2 authz bypass | NOISE (authentik does not expose gRPC authz) |
| CVE-2026-33816 | jackc/pgx/v5 | Memory-safety vulnerability | WATCH |
| CVE-2026-33845 | gnutls | DTLS DoS | NOISE (no DTLS) |
| CVE-2026-42010 | gnutls | NUL-byte auth bypass | NOISE (authentik uses Python TLS, not gnutls in user-path) |
| CVE-2026-7598 | libssh2 | username overflow | NOISE (no outbound SSH) |
| CVE-2025-68121 | go stdlib | TLS session resumption | NOISE (mTLS not configured) |

**Production impact.** Every critical in the authentik image is in a bundled library that authentik's runtime does not call on a reachable path. The pgx memory-safety finding is the only one to actually track: it can affect the DB-driver path on every request to authentik, but realising it requires server-controlled malicious responses from postgres, which is on `--internal` `authentik-db`. **Watch upstream for an authentik release that bumps pgx.**

---

### openwebui — WATCH

| Image | Pinned tag | C | H | M | L |
|---|---|---:|---:|---:|---:|
| `ghcr.io/open-webui/open-webui` | `0.9.5` | 30 | 259 | 1069 | 801 |

**Notable findings:** 30 criticals, almost all in bundled OS libraries: `mbedtls` (CVE-2026-34875 FFDH buffer overflow, CVE-2026-34873 TLS-1.3 client impersonation), `ffmpeg` (CVE-2026-40962 CENC subsample OOB write), `mesa` (CVE-2026-40393 GPU OOB), `gnutls`, `libssh2`, `libaom`. These exist in the image because the upstream ML stack pulls them in transitively (CUDA, audio/video processing, GPU acceleration).

**Production impact.** Open WebUI's runtime calls almost none of these libraries on a network-reachable path. The mbedTLS client-impersonation requires the **container** to be a TLS server presenting client certs — open-webui isn't. FFmpeg is invoked only if you upload media files with a specific codec mix; bound by your local user. The image is large (~6.7 GB) precisely because it ships an entire ML stack — `[WATCH]` until upstream rebases on a leaner base, but no immediate action.

---

### baserow — WATCH

| Image | Pinned tag | C | H | M | L |
|---|---|---:|---:|---:|---:|
| `baserow/baserow` | `2.2.2` | 9 | 91 | 197 | 165 |
| `postgres` | `18.4` | 1 | 26 | 74 | 115 |

**Notable findings:**

| CVE | Component | Title | Tag |
|---|---|---|---|
| CVE-2026-30836 | `smallstep/certificates` | Unauthenticated certificate issuance via SCEP | NOISE (Baserow does not expose the SCEP endpoint) |
| CVE-2026-33186 | `grpc-go` | HTTP/2 authz bypass | NOISE (Baserow does not use grpc authz interceptors) |
| CVE-2026-7210 | python3.13 | XML parser entropy | WATCH (only if you import attacker-controlled XML) |
| CVE-2026-7598 | libssh2 | username overflow | NOISE (no outbound SSH) |
| CVE-2026-42010, -33845 | gnutls | NUL auth-bypass, DTLS DoS | NOISE |
| CVE-2026-31789 | openssl | 32-bit X.509 heap overflow | NOISE (amd64) |

**Production impact.** Baserow imports SCEP CA code and gRPC libs but doesn't expose them. The only finding worth watching is the Python XML entropy issue — only relevant if you build workflows around uploading XML.

---

### docuseal — CONDITIONAL

| Image | Pinned tag | C | H | M | L |
|---|---|---:|---:|---:|---:|
| `docuseal/docuseal` | `3.0.0` | 3 | 6 | 4 | 1 |
| `postgres` | `18.4` | 1 | 26 | 74 | 115 |

**Notable findings:**

| CVE | Component | Title | Tag |
|---|---|---|---|
| CVE-2026-42257 | `net-imap` | CRLF command injection via unvalidated input | **CONDITIONAL** |
| CVE-2026-42258 | `net-imap` | Net::IMAP client | **CONDITIONAL** |
| CVE-2026-33210 | `json` (Ruby) | Format-string DoS / info disclosure | NOISE (Ruby JSON is internal; no user-controlled format string) |

**Production impact.** DocuSeal includes `net-imap` for the "incoming-email signing-flow" feature. If your `.env` does **not** define `SMTP_INBOUND_*` / IMAP-pull settings, that code path is never invoked — `[NOISE]`. If you do enable it, an attacker who can send a crafted email to that mailbox can inject IMAP commands — `[ACTION]`. Default deployments don't enable inbound IMAP.

---

### navidrome — WATCH

| Image | Pinned tag | C | H | M | L |
|---|---|---:|---:|---:|---:|
| `deluan/navidrome` | `0.61.2` | 4 | 21 | 9 | 4 |

**Notable findings:** All 4 criticals are Alpine OS libraries — `libcrypto3/libssl3` (CVE-2026-31789, 32-bit only — amd64-safe), `gnutls` (CVE-2026-33845 DTLS DoS, CVE-2026-42010 NUL auth-bypass — Navidrome doesn't use gnutls for any user-reachable path).

**Production impact.** None of the four criticals affect Navidrome's reachable code path. `[NOISE]` collectively. Watch for the next 0.61.x Alpine rebase.

---

### dockhand — CONDITIONAL

| Image | Pinned tag | C | H | M | L |
|---|---|---:|---:|---:|---:|
| `fnsys/dockhand` | `v1.0.29` | 4 | 25 | 42 | 2 |
| `postgres` | `18.4-alpine3.23` | 1 | 14 | 26 | 1 |
| `tecnativa/docker-socket-proxy` | `0.3` | 0 | 2 | 2 | 0 |

**Notable findings:**

| CVE | Component | Title | Tag |
|---|---|---|---|
| CVE-2026-33747 | `docker-cli-buildx`, `docker-compose` | BuildKit: arbitrary file write + RCE via untrusted frontend | **CONDITIONAL** |
| CVE-2026-33186 | `docker-compose` | gRPC-Go authz bypass | NOISE |
| CVE-2026-27143 | `docker-cli` | Go cmd/compile bounds-check elimination | NOISE |
| CVE-2025-26519 | `musl-libc` (docker-socket-proxy) | Out-of-bounds write | NOISE (only callable by Dockhand itself, which speaks JSON Engine API, not crafted shellcode) |

**Production impact.** The BuildKit RCE fires when you `docker buildx build` a Dockerfile that uses an attacker-controlled `# syntax=...` frontend directive. If you only manage your own templates through Dockhand and never run third-party Compose builds, you'll never hit it. **Pin your `# syntax=` lines to known-good frontend digests if you do build third-party content.**

The postgres-alpine numbers double-count with other templates that use postgres.

---

### zulip — CONDITIONAL

| Image | Pinned tag | C | H | M | L |
|---|---|---:|---:|---:|---:|
| `ghcr.io/zulip/zulip-server` | `12.0-0` | 2 | 180 | 1585 | 131 |
| `postgres` | `18.4` | 1 | 26 | 74 | 115 |
| `memcached` | `1.6.42-alpine3.23` | 0 | 0 | 0 | 0 |
| `rabbitmq` | `4.2.6` | 0 | 0 | 18 | 3 |
| `redis` | `7.4.9-alpine3.21` | 0 | 0 | 0 | 0 |

**Notable findings:**

| CVE | Component | Title | Tag |
|---|---|---|---|
| CVE-2026-42208 | `litellm` | Unauthorized data access via SQL injection | **CONDITIONAL** |
| CVE-2026-33186 | `grpc-go` | HTTP/2 authz bypass | NOISE |

**Production impact.** LiteLLM is shipped inside Zulip 12.x because of the optional "Zulip AI" bot. If you have not configured an LLM provider key in your Zulip admin panel, that code never runs — `[NOISE]`. If you do use the AI bot, the LiteLLM SQL injection lets a Zulip user query the LiteLLM-internal SQLite db (model usage/rate-limit data, not Zulip message data). Limited blast radius even when exploited.

Zulip's 180 highs are dominated by Python stack transitive deps + Go-stdlib in supervisord helpers; none of the high-severity findings I sampled were exploitable on a fronted-by-Caddy deployment.

---

### serpbear — NOISE

| Image | Pinned tag | C | H | M | L |
|---|---|---:|---:|---:|---:|
| `towfiqi/serpbear` | `3.1.0` | 2 | 27 | 39 | 5 |

**Notable findings:** Both criticals are `CVE-2026-31789` (OpenSSL 32-bit X.509 heap overflow) — your host is amd64, this code path never runs.

**Production impact.** `[NOISE]`.

---

### stoat — CONDITIONAL (livekit)

| Image | Pinned tag | C | H | M | L |
|---|---|---:|---:|---:|---:|
| `ghcr.io/stoatchat/livekit-server` | `v1.9.13` | 3 | 21 | 16 | 0 |
| `ghcr.io/stoatchat/for-web` | `0b94704` | 2 | 16 | 11 | 0 |
| `ghcr.io/stoatchat/api` | `v0.12.1` | 0 | 1 | 9 | 12 |
| `ghcr.io/stoatchat/*` (8 other services) | `v0.12.1` | 0 | 1 | 9 | 12 |
| `mongo` | `8.3.2` | 1 | 53 | 61 | 4 |
| `caddy` | `2.11.3` | 0 | 1 | 14 | 0 |
| `alpine`, `garage`, `rabbitmq-alpine`, `redis-alpine` | various | 0 | 0 | 0 | 0 |

**Notable findings:**

| CVE | Component | Title | Tag |
|---|---|---|---|
| CVE-2026-31789 | openssl | 32-bit X.509 heap overflow | NOISE (amd64) |
| CVE-2026-33186 | grpc-go | HTTP/2 authz bypass | **CONDITIONAL** (LiveKit uses gRPC server-streaming for its API — review whether you ship authz interceptors) |
| CVE-2026-34986 | go-jose/v3 | JWE DoS via crafted JSON | NOISE (Caddy's default JOSE module not used in stoat config) |

**Production impact.** The stoat ecosystem is a real-time chat platform — most criticals/highs are Go-stdlib DoS variants that matter primarily for unauthenticated front-of-house components. LiveKit's gRPC authz finding is the one to track if you expose LiveKit to the public internet.

---

## Filtered Noise

These CVEs appeared repeatedly across many images and were deliberately collapsed to `[NOISE]` after triage. Listed here so you can see what was filtered and double-check the reasoning:

| CVE pattern | Why it didn't make the cut |
|---|---|
| `CVE-2026-31789` (OpenSSL 32-bit X.509 heap overflow) | Affects only `i386` / 32-bit builds. Your hosts are `amd64`. |
| `CVE-2025-68121` (Go stdlib TLS session resumption) | Triggers only when a Go service terminates TLS for **untrusted** clients. Every postgres/mongo/mariadb in this repo is on an `--internal` Docker network and does not present TLS to external callers. |
| `CVE-2026-33845` (GnuTLS DTLS zero-length fragment DoS) | DTLS (the UDP variant of TLS) is not used by any service in this repo. |
| `CVE-2026-42010` (GnuTLS NUL-byte auth bypass) | Triggers on GnuTLS-based TLS-PSK auth; no service here uses GnuTLS TLS-PSK in a user-reachable path. |
| `CVE-2026-7598` (libssh2 username overflow) | Affects outbound SSH from the container. No template SSHes outbound to attacker-controlled hosts. |
| `CVE-2026-33186` (gRPC-Go HTTP/2 path authz bypass) | Requires the service to use `authz` interceptors with path-based rules — most images bundle the lib but don't use it that way. |
| `CVE-2026-6473` ... `CVE-2026-6638` (libpq highs) | These are PostgreSQL **server** CVEs. Trivy matches them against `libpq` (the **client** library) which is bundled into apps that **talk to** Postgres but don't run a server. Not exploitable on the client. |
| `CVE-2026-40393` (Mesa GPU OOB) | Requires the container to be granted GPU device access. None of these templates pass `--gpus`. |
| `CVE-2026-40962` (FFmpeg CENC subsample OOB) | Requires the container to decode CENC-encrypted media from an attacker. No template in this repo processes untrusted DRM-encrypted media. |
| `CVE-2026-7333..7356` (Chromium use-after-free, OOB read/write) | Bundled inside `uptime-kuma`'s puppeteer; only reachable if browser-based monitors are enabled. See the uptime-kuma section. |
| `CVE-2023-45853` (zlib `zipOpenNewFileInZip4_6` overflow) | Triggers on opening attacker-supplied ZIP files. No service in this repo opens ZIPs from untrusted input. |

## Hardening that reduces the impact of the rest

Several CVEs that would normally be `[ACTION]` are collapsed to `[NOISE]` or `[WATCH]` because of the existing per-template hardening:

| Mitigation | Effect on CVE class |
|---|---|
| `cap_drop: ALL` + minimum `cap_add` | Most "local privilege escalation" / "container breakout" paths are closed at the kernel layer. Even an RCE inside the container can't `mount`, can't load kernel modules, can't escalate via setuid binaries. |
| `security_opt: no-new-privileges` | Setuid binaries inside the container can't acquire caps mid-process. Defeats most local-privesc gadgets. |
| `ipc: private` | SysV / POSIX IPC attacks across containers are not possible. |
| Internal-only `--internal` networks for DB tier | postgres/mongo/mariadb/redis are not reachable from the public internet. Any "server-side" CVE in those services requires an attacker who has already compromised an app container. |
| `127.0.0.1` binding on every admin UI | Admin endpoints only reachable through the reverse proxy. Caddy / Pangolin can add rate limiting and auth on top. |
| `tmpfs` for ephemeral writes | Many "write to /tmp + race" / "world-writable temp file" CVE patterns are killed by `noexec,nosuid,size=...`. |
| Resource limits (`memory`, `cpus`, `pids`) | DoS-class CVEs (most of the Go-stdlib pile) can't take down the host — only the affected container, which `restart: unless-stopped` will recycle. |

## Recommended actions (in priority order)

1. **n8n 2.21.4** — five active criticals in n8n itself (RCE, sandbox escape, file read). Pin to whatever fixed release is published; reduce trust boundary for untrusted HTTP/Git/XML inputs in workflows.
2. **meshcentral 1.1.59-mongodb** — handlebars template RCE. Watch upstream; consider exposing only via Pangolin with auth.
3. **uptime-kuma 2.3.2** — only if you enable browser-based monitors. If not, treat as `[NOISE]`. If yes, disable them or upgrade weekly.
4. **docuseal inbound IMAP** — only if you've enabled it. Default `.env` ships it disabled.

Everything else falls into "track upstream for the next image rebase". The hardened compose configs in this repo absorb most of the residual risk.

---

## Re-running the audit

```bash
# Fresh DB
trivy image --download-db-only

# Single image
trivy image --severity CRITICAL,HIGH,MEDIUM,LOW --scanners vuln \
  --no-progress --format table <image>:<tag>

# All 43 in this repo: re-use the four group scripts saved at /tmp/audit-scans/group-{a,b,c,d}.sh
```

The raw JSON for every scan from this audit is at `/tmp/audit-scans/*.json` (43 files).
