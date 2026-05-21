# Contributing

Thanks for considering a contribution. This repo ships **production-ready, security-hardened Docker Compose templates**, so contributions are reviewed against a strict hardening baseline rather than purely on "does it run."

## Quick start

1. **Fork** the repository.
2. **Create a feature branch** off `main`. Branch names should describe the change scope:
   - `feature/<template-name>` for new templates (e.g. `feature/wireguard-easy`)
   - `harden/<area>` for security improvements
   - `fix/<area>` for bug fixes
   - `docs/<topic>` for documentation-only changes
   - `chore/<topic>` for tooling, CI, or housekeeping
3. **Commit** in [Conventional Commits](https://www.conventionalcommits.org/) style. The repo's Renovate config uses semantic commits (`chore(deps): ...`), so PR titles benefit from the same shape.
4. **Push** and **open a Pull Request** against `main`.
5. **Wait for CI**. See [Required CI Checks](#required-ci-checks) below.

## Template Guidelines

New templates must match the hardening baseline. Every new `docker-compose.yml` MUST include, for every service:

- **Pinned image tag** — no `:latest`, no floating major. Renovate handles version bumps.
- **`cap_drop: ALL`** plus the minimum `cap_add` you've **verified** by trim-and-retest. Don't copy `cap_add` lists blindly from upstream docs.
- **`security_opt: ["no-new-privileges:true"]`** and **`ipc: private`** on every service.
- **`deploy.resources.limits`** covering `memory`, `cpus`, and `pids`. Pick numbers based on observed first-boot + steady-state load.
- **A working `healthcheck`** with a `start_period` matched to the slowest first-boot path (DB migrations, asset compilation, etc.).
- **Web UIs bound to `127.0.0.1` only** — public exposure is the responsibility of the user's reverse proxy (Caddy, Pangolin, Nginx, Traefik).
- **Database / cache tier on an external `--internal` Docker network**. The internal network MUST have no public-facing services attached.

Additional requirements at the template directory level:

- **`.env.example`** tracked, real `.env` git-ignored. Required vars use `${VAR:?error}` so the stack fails fast if you forget one. **Never commit real secrets** — the repo has GitHub secret scanning + push protection enabled, but you should still verify locally.
- **`README.md`** documenting the exact networks to `docker network create`, the required `.env` values, ports exposed, persistent data paths, and any host-side prep (UID/GID, sysctl, etc.).
- **Optional but recommended:** an `init-data.sh` for creating non-root DB users on first boot.

## Required CI checks

Every PR runs the following workflows automatically. **The `scan` check is required for merge** via branch protection on `main`.

| Workflow | What it does | Required? |
|---|---|---|
| `scan` (pr-cve-gate) | Trivy CVE delta between PR HEAD and base for changed compose images; sticky comment posted | ✅ Yes |
| `misconfig` (pr-misconfig-scan) | Trivy IaC misconfiguration scan (HIGH + CRITICAL) | Informational |
| `lint` (actionlint) | Workflow YAML linting; runs on `.github/workflows/**` changes | Informational |
| `Analyze (actions)` | GitHub CodeQL on workflow files | Informational |
| `CodeQL` | GitHub CodeQL on code | Informational |

If the CVE delta or misconfig output flags something legitimate, fix it. If a finding is a justified exception (e.g., the docker-socket-proxy in the dockhand stack), document the justification in the PR and (for misconfig) add an entry to `.trivyignore` with a comment.

## Reporting security issues

**Do not file a public issue for security vulnerabilities.** See [SECURITY.md](SECURITY.md) for the disclosure process.

## License of contributions

By submitting a Pull Request you agree that your contribution is released under the project's [MIT License](LICENSE).

## Code of Conduct

All contributors are expected to follow the [Code of Conduct](CODE_OF_CONDUCT.md).

## Tips for a smooth review

- **One concern per PR.** A new template, a hardening fix, and a docs cleanup should be three PRs, not one.
- **Include reasoning, not just the change.** A commit message that says *why* (and what you tried that didn't work) saves review cycles.
- **If you remove a `cap_add` or relax a limit, prove it still works** — paste the test output or a brief log snippet in the PR description.
- **Match the existing voice in READMEs and commit messages.** Concise, direct, technically specific. Avoid filler.
