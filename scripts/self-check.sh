#!/usr/bin/env bash
# SPDX-License-Identifier: PMPL-1.0-or-later
# Self-Check Script — infrastructure-automation
#
# REFLEXIVE: The system inspects its own state and reports discrepancies
# between desired configuration (group_vars) and actual system state.
#
# This script embodies the reflexive design principle: the infrastructure
# can observe and describe itself without external tooling.
#
# Usage: ./scripts/self-check.sh [--json]

set -euo pipefail

# ── Config ────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
JSON_MODE="${1:-}"
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_SKIPPED=0
RESULTS=()

# ── Colours ───────────────────────────────────────────────────
if [ "$JSON_MODE" = "--json" ]; then
    pass() { RESULTS+=("{\"check\":\"$1\",\"status\":\"pass\"}"); CHECKS_PASSED=$((CHECKS_PASSED + 1)); }
    fail() { RESULTS+=("{\"check\":\"$1\",\"status\":\"fail\",\"detail\":\"$2\"}"); CHECKS_FAILED=$((CHECKS_FAILED + 1)); }
    skip() { RESULTS+=("{\"check\":\"$1\",\"status\":\"skip\",\"reason\":\"$2\"}"); CHECKS_SKIPPED=$((CHECKS_SKIPPED + 1)); }
else
    GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
    pass() { printf "${GREEN}[PASS]${NC} %s\n" "$1"; CHECKS_PASSED=$((CHECKS_PASSED + 1)); }
    fail() { printf "${RED}[FAIL]${NC} %s — %s\n" "$1" "$2"; CHECKS_FAILED=$((CHECKS_FAILED + 1)); }
    skip() { printf "${YELLOW}[SKIP]${NC} %s — %s\n" "$1" "$2"; CHECKS_SKIPPED=$((CHECKS_SKIPPED + 1)); }
    info() { printf "${BLUE}[....]${NC} %s\n" "$1"; }
fi

[ "$JSON_MODE" != "--json" ] && {
    echo "infrastructure-automation — Self-Check"
    echo "═══════════════════════════════════════"
    echo "Reflexive inspection: comparing desired vs actual state"
    echo ""
}

# ── Package Checks ────────────────────────────────────────────
[ "$JSON_MODE" != "--json" ] && info "Checking packages..."

for pkg in vim git htop curl wget tree jq tmux; do
    if command -v "$pkg" &>/dev/null; then
        pass "Package: $pkg installed"
    else
        fail "Package: $pkg" "not found in PATH"
    fi
done

# Check ripgrep (binary name differs from package name)
if command -v rg &>/dev/null; then
    pass "Package: ripgrep installed"
else
    fail "Package: ripgrep" "not found in PATH"
fi

# ── Service Checks ────────────────────────────────────────────
[ "$JSON_MODE" != "--json" ] && info "Checking services..."

for svc in sshd crond; do
    if systemctl is-active --quiet "$svc" 2>/dev/null; then
        pass "Service: $svc running"
    elif systemctl is-active --quiet "${svc}.service" 2>/dev/null; then
        pass "Service: $svc running"
    else
        fail "Service: $svc" "not running or not found"
    fi
done

# ── Firewall Checks ──────────────────────────────────────────
[ "$JSON_MODE" != "--json" ] && info "Checking firewall..."

if systemctl is-active --quiet firewalld 2>/dev/null; then
    pass "Firewall: firewalld running"

    if firewall-cmd --query-service=ssh --zone=public &>/dev/null; then
        pass "Firewall: SSH allowed in public zone"
    else
        fail "Firewall: SSH" "not allowed in public zone"
    fi
else
    skip "Firewall" "firewalld not running"
fi

# ── User Checks ──────────────────────────────────────────────
[ "$JSON_MODE" != "--json" ] && info "Checking users..."

if id "hyper" &>/dev/null; then
    pass "User: hyper exists"
    if groups hyper 2>/dev/null | grep -q wheel; then
        pass "User: hyper in wheel group"
    else
        fail "User: hyper" "not in wheel group"
    fi
else
    fail "User: hyper" "does not exist"
fi

# ── Podman Checks ────────────────────────────────────────────
[ "$JSON_MODE" != "--json" ] && info "Checking Podman..."

if command -v podman &>/dev/null; then
    pass "Container: Podman available"

    SOCKET_PATH="/run/user/$(id -u)/podman/podman.sock"
    if [ -S "$SOCKET_PATH" ]; then
        pass "Container: Podman socket active"
    else
        skip "Container: Podman socket" "not active (run: systemctl --user enable --now podman.socket)"
    fi
else
    skip "Container: Podman" "not installed"
fi

# ── Ansible Checks ───────────────────────────────────────────
[ "$JSON_MODE" != "--json" ] && info "Checking Ansible..."

if command -v ansible &>/dev/null; then
    pass "Tool: Ansible available"
else
    fail "Tool: Ansible" "not found (run: scripts/bootstrap.sh)"
fi

# ── Terraform Checks ─────────────────────────────────────────
if command -v terraform &>/dev/null; then
    pass "Tool: Terraform available"
else
    skip "Tool: Terraform" "not installed (optional — only for container provisioning)"
fi

# ── File Checks ──────────────────────────────────────────────
[ "$JSON_MODE" != "--json" ] && info "Checking managed files..."

if [ -f /etc/motd ]; then
    if grep -q "infrastructure-automation\|Managed by Ansible" /etc/motd 2>/dev/null; then
        pass "File: /etc/motd managed"
    else
        skip "File: /etc/motd" "exists but not managed by this repo"
    fi
else
    skip "File: /etc/motd" "not present"
fi

# ── Report ────────────────────────────────────────────────────
echo ""

if [ "$JSON_MODE" = "--json" ]; then
    echo "{"
    echo "  \"tool\": \"self-check\","
    echo "  \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
    echo "  \"summary\": {"
    echo "    \"passed\": $CHECKS_PASSED,"
    echo "    \"failed\": $CHECKS_FAILED,"
    echo "    \"skipped\": $CHECKS_SKIPPED,"
    echo "    \"total\": $((CHECKS_PASSED + CHECKS_FAILED + CHECKS_SKIPPED))"
    echo "  },"
    echo "  \"checks\": [$(IFS=,; echo "${RESULTS[*]}")]"
    echo "}"
else
    echo "═══════════════════════════════════════"
    printf "Results: ${GREEN}%d passed${NC}, ${RED}%d failed${NC}, ${YELLOW}%d skipped${NC}\n" \
        "$CHECKS_PASSED" "$CHECKS_FAILED" "$CHECKS_SKIPPED"

    if [ "$CHECKS_FAILED" -gt 0 ]; then
        echo ""
        echo "To fix failures, run:"
        echo "  just apply"
        exit 1
    else
        echo ""
        echo "System state matches desired configuration."
    fi
fi
