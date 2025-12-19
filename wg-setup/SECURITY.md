# Security Policy

## Overview

This project combines WireGuard VPN, Pi-hole DNS filtering, and Unbound DNS resolver to create a secure, privacy-focused network stack. Security is a top priority.

## Security Features

### Encryption
- **WireGuard VPN**: State-of-the-art Noise protocol framework with ChaCha20, Poly1305, BLAKE2, and Curve25519
- **DNS-over-TLS**: All DNS queries encrypted to Quad9 (9.9.9.9) on port 853
- **DNSSEC Validation**: Quad9 validates DNSSEC signatures to prevent DNS spoofing

### Container Hardening
- **Capability Dropping**: Containers run with minimal Linux capabilities
- **No New Privileges**: `security_opt: no-new-privileges:true` prevents privilege escalation
- **Read-only where possible**: Configuration files mounted as read-only
- **Health Checks**: Continuous monitoring of all services

### Network Security
- **Isolated Docker Network**: Services communicate on private 10.8.1.0/24 subnet
- **No Direct Internet Access**: Pi-hole and Unbound only accessible through VPN or Docker network
- **Static IP Addresses**: Predictable network configuration for firewall rules

## Reporting a Vulnerability

If you discover a security vulnerability in this configuration:

1. **Do NOT open a public issue**
2. **Contact the maintainers privately**
3. **Provide detailed information**:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

## Security Best Practices

### Before Deployment

1. **Change all default passwords** in `.env`:
   ```bash
   WG_ADMIN_PASSWORD=<strong-unique-password>
   PIHOLE_PASSWORD=<strong-unique-password>
   ```

2. **Generate strong passwords**:
   ```bash
   openssl rand -base64 32
   ```

3. **Verify file permissions**:
   ```bash
   chmod 600 .env
   chmod 644 docker-compose.yml
   chmod 644 unbound/unbound.conf
   ```

### After Initial Setup

1. **Remove INIT_* variables** from `docker-compose.yml` after first run

2. **Restrict web interface access** to localhost:
   ```yaml
   ports:
     - "127.0.0.1:80:80/tcp"
     - "127.0.0.1:51821:51821/tcp"
   ```

3. **Configure host firewall**:
   ```bash
   sudo ufw default deny incoming
   sudo ufw allow 51820/udp  # WireGuard only
   sudo ufw enable
   ```

4. **Use SSH tunnels** for remote administration:
   ```bash
   ssh -L 8080:127.0.0.1:80 -L 51821:127.0.0.1:51821 user@server
   ```

### Ongoing Security

1. **Keep containers updated**:
   ```bash
   docker compose pull
   docker compose up -d
   ```

2. **Monitor logs** for suspicious activity:
   ```bash
   docker compose logs -f
   ```

3. **Review Pi-hole query logs** for anomalies

4. **Backup configurations** regularly:
   ```bash
   tar -czvf backup-$(date +%Y%m%d).tar.gz .env unbound/ pihole/ wireguard/
   ```

## Third-Party Security

This project relies on well-maintained, security-focused projects:

| Component | Security Contact | CVE Tracking |
|-----------|-----------------|--------------|
| WireGuard | security@wireguard.com | [CVE List](https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=wireguard) |
| Pi-hole | [GitHub Security](https://github.com/pi-hole/pi-hole/security) | [Advisories](https://github.com/pi-hole/pi-hole/security/advisories) |
| Unbound | [NLnet Labs](https://nlnetlabs.nl/projects/unbound/security/) | [Advisories](https://nlnetlabs.nl/projects/unbound/security/) |
| Quad9 | security@quad9.net | N/A |

## Known Limitations

1. **DNS queries visible within VPN tunnel**: While encrypted to Quad9, queries are visible to Pi-hole/Unbound
2. **Metadata exposure**: Connection timing and packet sizes may leak information
3. **Single point of failure**: If VPS goes down, VPN access is lost
4. **Trust in Quad9**: DNS queries are visible to Quad9 after decryption

## Security Checklist

- [ ] Changed all default passwords
- [ ] Verified file permissions (600 for .env)
- [ ] Removed INIT_* variables after setup
- [ ] Configured host firewall
- [ ] Restricted web UI to localhost (production)
- [ ] Set up regular backups
- [ ] Enabled automatic container updates
- [ ] Reviewed Pi-hole blocklists for your needs
