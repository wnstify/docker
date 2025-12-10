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

- Keep Docker and all images updated regularly
- Use the included Watchtower template for automatic updates
- Review container logs for suspicious activity
- Run containers with `no-new-privileges:true` (already configured)

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

All templates include these security measures by default:

| Feature | Purpose |
|---------|---------|
| `security_opt: no-new-privileges:true` | Prevents privilege escalation |
| Localhost port binding (`127.0.0.1:port:port`) | Services only accessible via reverse proxy |
| Non-root database users | Principle of least privilege |
| Health checks | Ensures service availability |
| External Docker networks | Network isolation between stacks |
| PUID/PGID configuration | Consistent file ownership |

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