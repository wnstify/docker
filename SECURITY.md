# Security Policy

At **Webnestify**, we take the security of our projects seriously. If you discover any security vulnerabilities or have concerns regarding the security of this repository, we encourage you to report them responsibly.

---

## Supported Versions

We provide security updates for the following:

| Version | Supported |
|---------|-----------|
| Latest (main branch) | ✅ Yes |
| Older releases | ❌ No |

We recommend always using the latest version of these templates.

---

## Reporting a Vulnerability

### How to Report

1. **Do NOT** disclose the vulnerability publicly (e.g., in GitHub Issues, forums, or social media)
2. Navigate to the **Security** tab of this repository on GitHub
3. Click **"Report a vulnerability"** to create a private security advisory
4. Provide a detailed description including:
   - Affected template(s) or file(s)
   - Steps to reproduce the issue
   - Potential impact assessment
   - Proof of Concept (PoC) if applicable
   - Suggested fix (if you have one)

### What to Expect

After receiving your report, we will:

- **Acknowledge** receipt within 48 hours
- **Investigate** and assess the vulnerability
- **Communicate** progress and updates with you
- **Credit** you in the fix (unless you prefer anonymity)
- **Release** a patch as soon as possible

---

## Security Best Practices for Users

When deploying these templates, please follow these guidelines:

### Credentials & Secrets

- **Never** commit `.env` files with real credentials to version control
- Use strong, unique passwords for all services
- Rotate credentials periodically
- Use a secrets manager for production environments

### Network Security

- Always use a reverse proxy with HTTPS (templates bind to localhost by default)
- Keep firewall rules restrictive — only expose necessary ports
- Use Docker networks to isolate services
- Consider using a VPN for administrative access

### Container Security

- Keep Docker and all images updated regularly — `docker compose pull && docker compose up -d` against the pinned tags in each template's compose file
- Re-run the Trivy scan after upgrading; the methodology is documented in [AUDIT.md](AUDIT.md)
- Review container logs for suspicious activity
- The full hardening baseline (`cap_drop: ALL`, `no-new-privileges`, `ipc: private`, internal-only DB networks, tmpfs for ephemeral writes, per-container resource limits) is already configured in every template

### Backup & Recovery

- Regularly backup persistent volumes and databases
- Test your backup restoration process
- Store backups in a separate location

---

## Scope

This security policy covers:

- ✅ All Docker Compose configurations in this repository
- ✅ Environment variable templates and examples
- ✅ Initialization scripts (`init-data.sh`)
- ✅ Documentation that could lead to insecure configurations

### Out of Scope

- ❌ Vulnerabilities in upstream Docker images (report to the respective maintainers)
- ❌ Issues in third-party applications themselves (Jellyfin, n8n, etc.)
- ❌ User misconfiguration or failure to follow security guidelines
- ❌ Self-hosted environment security (your responsibility)

If you find a vulnerability in an upstream project, please report it directly to that project's maintainers.

---

## Security Features in Our Templates

Every template ships with the same hardened baseline:

| Layer | Setting | Effect |
|---|---|---|
| Capabilities | `cap_drop: ALL` with a minimum verified `cap_add` per role | Most database / cache containers run with **zero** caps |
| Privileges | `security_opt: no-new-privileges:true` | Setuid binaries can't gain caps mid-process |
| IPC | `ipc: private` | Isolated SysV / POSIX IPC namespace |
| Image tags | Specific patch versions, never `:latest` or floating major | Reproducible deploys; supply-chain pin |
| Network split | DB / cache tier on an `--internal` Docker network | Postgres / Redis / MongoDB / MariaDB have no internet egress |
| Public exposure | `127.0.0.1` bindings on every web UI | Only the reverse proxy can reach admin endpoints |
| Resources | `deploy.resources.limits` for memory / cpus / pids | DoS-class CVEs can't take down the host |
| Ephemeral writes | `tmpfs` with `size=` caps | No persistence required; race gadgets neutered |
| Auth | Postgres `SCRAM-SHA-256`; Redis `--requirepass`; non-root app DB user | Stronger than upstream defaults |
| Lifecycle | Healthchecks with `start_period` matched to first-boot | `docker compose ps` is a true signal |
| Secrets | `.env.example` tracked; `.env` git-ignored; `${VAR:?error}` on required vars | Service fails fast if a secret is missing |

## Vulnerability Scanning

The repo publishes [AUDIT.md](AUDIT.md) — a Trivy CVE scan of every image in every `docker-compose.yml`, triaged against the hardened configuration above. Each finding is tagged `[ACTION]`, `[WATCH]`, `[CONDITIONAL]`, or `[NOISE]` with the reasoning visible inline, so you can challenge any individual call. The audit is timestamped (scanner version + DB version + scan date) and refreshed each time the templates change materially.

Re-run it locally with:

```bash
trivy image --severity CRITICAL,HIGH,MEDIUM,LOW --scanners vuln <image>:<tag>
```

---

## Limitations

Please note:

- As an individual developer, response times may vary based on complexity
- Security in self-hosted environments is ultimately the user's responsibility
- These templates are provided as-is; please review them before production use
- We cannot guarantee immediate patches for all vulnerabilities

---

## Contact

For security-related inquiries that don't fit the vulnerability report process:

- **Email**: [contact@webnestify.cloud](mailto:contact@webnestify.cloud)
- **Website**: [webnestify.cloud/contact](https://webnestify.cloud/contact)

---

Thank you for helping keep this project and its users secure. Your responsible disclosure is greatly appreciated.