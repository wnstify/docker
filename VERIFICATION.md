# Verifying a Release

Every tagged release of this repository ships with two layers of cryptographic
provenance, both produced by the [`Release` workflow](.github/workflows/release.yml)
in GitHub Actions and verifiable by anyone with no shared secret:

1. **Sigstore keyless signature** over `SHA256SUMS` (cosign + Fulcio + Rekor).
2. **SLSA build-provenance attestation** for each release artifact
   (`actions/attest-build-provenance`).

The signing key is short-lived and tied to the workflow's OIDC identity —
there is no long-lived private key to leak or rotate.

## Prerequisites

- [`cosign`](https://docs.sigstore.dev/cosign/installation/) ≥ 2.0
- [`gh`](https://cli.github.com/) (GitHub CLI) ≥ 2.49 — for SLSA attestation
  verification
- `sha256sum` (GNU coreutils)

## 1. Download the release assets

Pick the version you want from the [Releases page](https://github.com/wnstify/docker/releases)
and download all four assets to the same directory. Example for
`v2026.05.21`:

```bash
TAG=v2026.05.21
BASE=wnstify-docker-${TAG#v}

gh release download "$TAG" \
  --repo wnstify/docker \
  --pattern "${BASE}.tar.gz" \
  --pattern "${BASE}.zip" \
  --pattern "SHA256SUMS" \
  --pattern "SHA256SUMS.sigstore.json" \
  --pattern "${BASE}.intoto.jsonl"
```

## 2. Verify file integrity (SHA256SUMS)

```bash
sha256sum -c SHA256SUMS
```

Expected: `OK` for every line. If any file is corrupted or tampered, this
will fail — stop here.

## 3. Verify the Sigstore signature on SHA256SUMS

This confirms that `SHA256SUMS` (and therefore the archives it covers) was
produced by **this repository's release workflow**, on a **tag matching `v*`**,
on GitHub's official runners.

The signature, signing certificate, and Rekor transparency-log inclusion
proof are all packaged in a single `SHA256SUMS.sigstore.json` bundle
(the modern Sigstore bundle format).

```bash
cosign verify-blob \
  --bundle SHA256SUMS.sigstore.json \
  --certificate-identity-regexp '^https://github\.com/wnstify/docker/\.github/workflows/release\.yml@refs/tags/v.*$' \
  --certificate-oidc-issuer    'https://token.actions.githubusercontent.com' \
  SHA256SUMS
```

Expected: `Verified OK`.

If you see `error: no matching signatures` or a certificate-identity
mismatch, treat the release as **untrusted** — it did not come from this
repo's release workflow.

## 4. Verify the SLSA build-provenance attestation

The provenance bundle (`${BASE}.intoto.jsonl`) is a Sigstore bundle wrapping
a SLSA v1 in-toto attestation. It links each archive byte-for-byte to the
workflow run, commit, and runner that produced it.

The same bundle is also stored in GitHub's Attestations API, so verification
works two ways:

### Online (via API — no bundle download required)

```bash
gh attestation verify "${BASE}.tar.gz" --repo wnstify/docker
gh attestation verify "${BASE}.zip"    --repo wnstify/docker
```

### Offline (using the bundled attestation file)

```bash
gh attestation verify "${BASE}.tar.gz" \
  --bundle "${BASE}.intoto.jsonl" \
  --repo  wnstify/docker
gh attestation verify "${BASE}.zip"    \
  --bundle "${BASE}.intoto.jsonl" \
  --repo  wnstify/docker
```

Expected for each: `Loaded digest …` followed by
`✓ Verification succeeded!` and a summary of the matched
`build.github.com` / `repository_id` predicate.

If the predicate's `workflow` field does **not** point at
`.github/workflows/release.yml` of `wnstify/docker`, treat the artifact as
untrusted.

## What's NOT being verified by these steps

- **Upstream container images.** This repo ships docker-compose templates;
  the images themselves are pulled from Docker Hub / GHCR / quay.io at
  runtime and are out of scope for these signatures. CVE state for those
  images is tracked separately in [`AUDIT.md`](AUDIT.md).
- **The `main` branch.** Only tagged releases are signed. If you clone
  `main`, you're trusting the GitHub branch-protection rules
  (`enforce_admins: true`, required `scan` check), not Sigstore.

## Reporting verification failures

If any of the above commands fail on a published release, please open a
private security advisory via [`SECURITY.md`](SECURITY.md) — do not file a
public issue.
