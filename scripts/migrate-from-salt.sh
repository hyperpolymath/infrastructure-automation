#!/usr/bin/env bash
# SPDX-License-Identifier: PMPL-1.0-or-later
# Salt Migration Helper — infrastructure-automation
#
# Assists with migrating from SaltStack to Ansible + Terraform.
# Checks current Salt state, backs up configs, and validates readiness.
#
# Usage: ./scripts/migrate-from-salt.sh

set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

ok()   { printf "${GREEN}[ok]${NC} %s\n" "$1"; }
info() { printf "${BLUE}[..]${NC} %s\n" "$1"; }
warn() { printf "${YELLOW}[!!]${NC} %s\n" "$1"; }
fail() { printf "${RED}[xx]${NC} %s\n" "$1"; }

echo "infrastructure-automation — Salt Migration Helper"
echo "══════════════════════════════════════════════════"
echo ""

# ── 1. Detect existing Salt installation ─────────────────────
info "Detecting SaltStack installation..."

SALT_CONTAINER_DIR="$HOME/salt-container"
SALT_FOUND=false

# Check for containerised Salt
if [ -d "$SALT_CONTAINER_DIR" ]; then
    ok "Found Salt container setup at $SALT_CONTAINER_DIR"
    SALT_FOUND=true

    # Check if containers are running
    if podman ps --format '{{.Names}}' 2>/dev/null | grep -q "salt-master"; then
        warn "Salt master container is RUNNING"
        echo "    You should stop it after verifying Ansible works:"
        echo "    cd $SALT_CONTAINER_DIR && ./salt-manage.sh stop"
    else
        ok "Salt containers are stopped"
    fi
fi

# Check for rpm-ostree layered Salt
if rpm -q salt-master &>/dev/null 2>&1; then
    warn "Salt is layered via rpm-ostree"
    echo "    Remove after migration: sudo rpm-ostree uninstall salt-master salt-minion"
    SALT_FOUND=true
fi

# Check for Salt binaries
if command -v salt-master &>/dev/null; then
    warn "salt-master binary found in PATH"
    SALT_FOUND=true
fi

if [ "$SALT_FOUND" = "false" ]; then
    ok "No SaltStack installation detected — clean slate"
fi

# ── 2. Backup existing Salt states ───────────────────────────
if [ -d "$SALT_CONTAINER_DIR/srv/salt" ]; then
    BACKUP_DIR="$HOME/salt-backup-$(date +%F)"
    info "Backing up Salt states to $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    cp -r "$SALT_CONTAINER_DIR/srv/salt" "$BACKUP_DIR/states" 2>/dev/null || true
    cp -r "$SALT_CONTAINER_DIR/srv/pillar" "$BACKUP_DIR/pillar" 2>/dev/null || true
    cp -r "$SALT_CONTAINER_DIR/config" "$BACKUP_DIR/config" 2>/dev/null || true
    ok "Salt configuration backed up to $BACKUP_DIR"
fi

# ── 3. Check Ansible readiness ───────────────────────────────
echo ""
info "Checking Ansible readiness..."

if command -v ansible &>/dev/null; then
    ok "Ansible is installed"
else
    fail "Ansible not found — run scripts/bootstrap.sh first"
    exit 1
fi

if command -v ansible-playbook &>/dev/null; then
    ok "ansible-playbook available"
else
    fail "ansible-playbook not found"
    exit 1
fi

# ── 4. Validate playbooks ────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

info "Validating Ansible playbooks..."
if ansible-playbook --syntax-check "${REPO_ROOT}/ansible/playbooks/site.yml" 2>/dev/null; then
    ok "Playbook syntax valid"
else
    fail "Playbook syntax errors detected"
fi

# ── 5. Dry run ────────────────────────────────────────────────
echo ""
info "Ready for migration dry run"
echo ""
echo "Recommended migration steps:"
echo "  1. Review:  vim ansible/inventory/group_vars/all.yml"
echo "  2. Dry run: just check"
echo "  3. Apply:   just apply"
echo "  4. Verify:  just self-check"
echo "  5. Stop Salt: cd ~/salt-container && ./salt-manage.sh stop"
echo ""
echo "See docs/MIGRATION-FROM-SALT.adoc for detailed guidance."
