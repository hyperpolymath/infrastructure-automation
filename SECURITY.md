<!-- SPDX-License-Identifier: PMPL-1.0-or-later -->
# Security Policy

## Reporting Vulnerabilities

Report security issues to: jonathan.jewell@open.ac.uk

Do NOT open public issues for security vulnerabilities.

## Security Model

This repository manages infrastructure configuration. Security considerations:

1. **Secrets**: Use Ansible Vault for all sensitive data. Never commit plaintext secrets.
2. **Access**: Ansible connects via SSH or local connection. Protect SSH keys.
3. **Privilege**: Tasks escalate to root only when necessary. Sudo rules use drop-in files.
4. **Containers**: Podman runs rootless (user namespace isolation).
5. **Firewall**: Default deny policy. Only explicitly allowed services are accessible.
6. **Audit**: The reflexive_reporter callback logs all state changes.

## Supported Versions

| Version | Supported |
|---------|-----------|
| 1.0.x   | Yes       |
