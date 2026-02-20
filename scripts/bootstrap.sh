#!/usr/bin/env bash
# SPDX-License-Identifier: PMPL-1.0-or-later
# Bootstrap Script — infrastructure-automation
#
# First-time setup: installs Ansible, Terraform, and required collections.
# Reflexive: this script checks its own prerequisites before proceeding.
# Idempotent: safe to run multiple times.
#
# Usage: ./scripts/bootstrap.sh

set -euo pipefail

# ── Colours ───────────────────────────────────────────────────
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

ok()   { printf "${GREEN}[ok]${NC} %s\n" "$1"; }
info() { printf "${BLUE}[..]${NC} %s\n" "$1"; }
warn() { printf "${YELLOW}[!!]${NC} %s\n" "$1"; }
fail() { printf "${RED}[xx]${NC} %s\n" "$1"; exit 1; }

# ── Locate repo root ─────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "infrastructure-automation — Bootstrap"
echo "────────────────────────────────────────"

# ── 1. Check Python ──────────────────────────────────────────
info "Checking Python..."
if command -v python3 &>/dev/null; then
    PY_VERSION=$(python3 --version)
    ok "Found $PY_VERSION"
else
    fail "Python 3 is required. Install with: sudo dnf install python3"
fi

# ── 2. Install/check pip ─────────────────────────────────────
info "Checking pip..."
if python3 -m pip --version &>/dev/null; then
    ok "pip available"
else
    info "Installing pip..."
    python3 -m ensurepip --user 2>/dev/null || \
        warn "Could not install pip. Try: sudo dnf install python3-pip"
fi

# ── 3. Install Ansible ───────────────────────────────────────
info "Checking Ansible..."
if command -v ansible &>/dev/null; then
    ANSIBLE_VERSION=$(ansible --version | head -1)
    ok "Found $ANSIBLE_VERSION"
else
    info "Installing Ansible..."
    python3 -m pip install --user ansible
    ok "Ansible installed"

    # Ensure ~/.local/bin is in PATH
    if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
        warn "Add to your shell profile: export PATH=\"\$HOME/.local/bin:\$PATH\""
        export PATH="$HOME/.local/bin:$PATH"
    fi
fi

# ── 4. Install Ansible collections ───────────────────────────
info "Installing Ansible collections..."
ansible-galaxy collection install -r "${REPO_ROOT}/ansible/requirements.yml" --force
ok "Collections installed"

# ── 5. Check/install Terraform ────────────────────────────────
info "Checking Terraform..."
if command -v terraform &>/dev/null; then
    TF_VERSION=$(terraform version -json 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin)['terraform_version'])" 2>/dev/null || terraform version | head -1)
    ok "Found Terraform $TF_VERSION"
else
    warn "Terraform not found."
    echo "    Install options:"
    echo "    1. asdf: asdf plugin add terraform && asdf install terraform latest"
    echo "    2. dnf:  sudo dnf install terraform"
    echo "    3. Manual: https://developer.hashicorp.com/terraform/install"
    echo ""
    echo "    Terraform is OPTIONAL — only needed for container provisioning."
    echo "    Ansible handles all configuration management without it."
fi

# ── 6. Check Podman ───────────────────────────────────────────
info "Checking Podman..."
if command -v podman &>/dev/null; then
    PODMAN_VERSION=$(podman version --format '{{.Client.Version}}' 2>/dev/null || podman --version)
    ok "Found Podman $PODMAN_VERSION"

    # Check Podman socket for Terraform integration
    SOCKET_PATH="/run/user/$(id -u)/podman/podman.sock"
    if [ -S "$SOCKET_PATH" ]; then
        ok "Podman socket active at $SOCKET_PATH"
    else
        info "Enabling Podman socket for Terraform integration..."
        systemctl --user enable --now podman.socket 2>/dev/null || \
            warn "Could not enable Podman socket. Run: systemctl --user enable --now podman.socket"
    fi
else
    warn "Podman not found. Container management will not be available."
fi

# ── 7. Check just ─────────────────────────────────────────────
info "Checking just (task runner)..."
if command -v just &>/dev/null; then
    ok "Found $(just --version)"
else
    warn "just not found. Install with: cargo install just"
    echo "    You can still run Ansible/Terraform directly without just."
fi

# ── 8. Verify setup ──────────────────────────────────────────
echo ""
echo "────────────────────────────────────────"
info "Verifying Ansible can reach localhost..."
if ansible localhost -m ping -o 2>/dev/null | grep -q "SUCCESS"; then
    ok "Ansible connectivity verified"
else
    warn "Ansible localhost ping failed. Check Python interpreter path."
fi

echo ""
echo "────────────────────────────────────────"
ok "Bootstrap complete!"
echo ""
echo "Next steps:"
echo "  1. Edit:  ansible/inventory/group_vars/all.yml"
echo "  2. Check: just check   (or: ansible-playbook -C ansible/playbooks/site.yml)"
echo "  3. Apply: just apply   (or: ansible-playbook ansible/playbooks/site.yml)"
