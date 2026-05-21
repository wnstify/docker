# Upgrade Testing Methodology

How this project pre-flight-tests high-risk dependency bumps before merging
the Renovate PR that introduces them. Patch-level image bumps are already
covered by `.github/workflows/pr-cve-gate.yml`; this document defines the
extra-care path for **major version bumps** (e.g. `mariadb 11 → 12`,
`redis 7 → 8`), **on-disk format changes** (e.g. Postgres major upgrades),
and **major bumps of trusted CI Actions**.

---

## When this methodology applies

| Change | Apply this? |
|---|---|
| Patch image bump (`mariadb 11.8.6 → 11.8.7`) | No — Renovate auto-merges per `renovate.json`; the CVE gate is the gate. |
| Minor image bump (`mariadb 11.8 → 11.9`) | Optional — apply if upstream changelog flags behaviour changes. |
| Major image bump (`mariadb 11 → 12`, `redis 7 → 8`, `mongo 7 → 8`) | **Yes.** |
| Major bump of a third-party Action (e.g. `actions/upload-artifact v4 → v7`) | **Yes** (changelog-review variant — see below). |
| Application-image bump (`jellyfin`, `n8n`, etc.) | No — application bumps are the user's choice; the CVE gate is the gate. |

---

## Hard isolation rules

These rules exist to guarantee a test cannot interact with anything running
on the host, including production stacks deployed from templates in this
repository.

1. **All test artefacts live in `/tmp/upgrade-tests/<test-name>/`.**
   Every compose file, env file, bind-mounted data directory, and result
   log goes under that path. Nothing under the project working directory.
2. **Compose project name is prefixed `tmp-test-`.** Use `name: tmp-test-<n>`
   in the compose file (or `docker compose -p tmp-test-<n>`).
3. **Container names are explicit and prefixed `tmp-test-<n>-`.** Never
   rely on auto-generated names — they collide on subsequent runs.
4. **Network names are explicit and prefixed `tmp-test-<n>-`.** Never use
   the default project network; another test may pick the same auto name.
5. **No `ports:` host bindings.** Verification happens through `docker exec`
   on the container, not from the host. This makes port conflicts
   structurally impossible.
6. **Bind mounts only into `/tmp/upgrade-tests/<n>/`.** No named volumes
   (they outlive the test), no bind mounts to host paths.
7. **Test credentials must be obvious placeholders.** Example:
   `TEST_DO_NOT_USE_pwd_<random>`. Never copy a value from a real `.env`.

---

## Per-test structure

For each major image bump:

### 1. Set up the test dir

```
mkdir -p /tmp/upgrade-tests/<n>/data
cd      /tmp/upgrade-tests/<n>
```

Write a minimal `compose.yml` containing only the service under test (plus
any sidecar required to exercise the upgrade path — e.g. an application
container that connects to the upgraded DB). Apply the isolation rules
above. Pin the **current** image tag from the live repo, not the new one.

### 2. Boot the current version

```
docker compose up -d
docker compose ps    # all services must reach healthy (or running, if no healthcheck)
```

If a healthcheck is defined upstream, wait for `healthy`. If not, wait for
the application's "ready" log line. **Do not proceed if any service is
unhealthy or crash-looping.**

### 3. Seed data

Use `docker exec` to write a minimal dataset that exercises the relevant
subsystem (a table + a few rows for SQL DBs; a key + value with persistence
for Redis; a collection + docs for Mongo). Capture the seeded state so the
post-upgrade query can compare.

### 4. Stop without removing volumes

```
docker compose stop      # NOT `down`. We need the bind-mounted data to persist.
```

### 5. Boot the new version on the same data dir

Edit `compose.yml` to bump only the image tag. Restart:

```
docker compose up -d
```

For DB upgrades that require an explicit migration command (e.g. some
MariaDB majors), run that command inside the new container before the
verify step. Note the command in the test report.

### 6. Verify

Required checks for a PASS:

- All services reach healthy / running.
- `docker logs <container>` since the new version started contains zero
  matches for `error|ERROR|Error|FATAL|panic` after filtering known-noise
  lines (filter rules MUST be explicit and noted in the report).
- The data seeded in step 3 is readable via `docker exec` query.
- For application-DB pairings: the application container reports a
  successful connection in its logs.

Any failed check = test FAILS.

### 7. Report

Write `/tmp/upgrade-tests/<n>/REPORT.md` with:

```
# <component> <old-version> → <new-version>

Date: YYYY-MM-DD HH:MM UTC
Status: PASS | FAIL

## Checks
- [x] Old version healthy        (boot timestamp ...)
- [x] Seed succeeded             (rows inserted: ...)
- [x] New version healthy        (boot timestamp ...)
- [x] Data readable post-upgrade (rows returned: ..., expected: ...)
- [x] No error lines in logs     (filter: ..., matches: 0)

## Logs (excerpt)
<paste relevant snippets>

## Notes
<any commands needed for the upgrade, any quirks observed>
```

### 8. Conditional cleanup

A test passes **only** when every required check in step 6 is green.

- **PASS**: tear down completely.
  ```
  docker compose down -v --remove-orphans
  rm -rf /tmp/upgrade-tests/<n>
  ```
- **FAIL or any required check red**: leave the artefacts in place.
  Investigate, file an issue, and only clean up after the investigation
  is documented (in the CHANGELOG or a follow-up PR).

The default state of `/tmp/upgrade-tests/` after a passing test run is
**empty**.

---

## Action bump methodology

GitHub Actions cannot be booted in isolation; testing happens by review.

For each major action bump:

1. Read the upstream `CHANGELOG.md` (or GitHub Releases page) for every
   release between our current pin and the target.
2. List every input, output, env var, and side effect of the action that
   our workflows depend on (grep `.github/workflows/`).
3. For each item, confirm it still exists at the target version with the
   same semantics. Note any required workflow edits.
4. **PASS** = no semantic break for our usage, OR the required workflow
   edits are made and pass `actionlint` locally + the existing CI checks.

Capture findings the same way as image bumps — write a per-action section
in `/tmp/upgrade-tests/actions/REPORT.md` and follow the same
conditional-cleanup rule.

---

## Verification line in `CHANGELOG.md`

Before the Renovate upgrade PR is merged, `CHANGELOG.md` `[Unreleased]`
**MUST** gain a `### Verified` block listing exactly what was tested and
the outcome. Example:

```markdown
### Verified
- `mariadb 11.8.6 → 12.2.2`: data dir survives boot, queries return seeded
  rows, no error lines in container logs. Tested 2026-05-21.
- `redis 7.4.9 → 8.0.6-alpine3.21`: AUTH still works, AOF persists across
  the upgrade, no error lines in container logs. Tested 2026-05-21.
- `actions/upload-artifact v4 → v7`: changelog review only. Breaking
  change: artifact immutability default flipped; we don't rely on artifact
  overwrite. No workflow edits required. Reviewed 2026-05-21.
```

The verification block is what makes the Renovate PR mergeable for the
classes of bump listed above. Without it, the maintainer's review must
note explicitly why no test was needed.

---

## Reproducing a previous test

The compose files in `/tmp/upgrade-tests/<n>/` are intentionally transient.
To re-run a test:

1. Inspect the current versions in the live `docker-compose.yml`.
2. Recreate the test dir per the structure above.
3. Skip the seed step if you only need a boot-and-logs check; include it
   if data compatibility is the concern.

The methodology is the artefact, not the individual test directories.
