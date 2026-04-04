# SPDX-License-Identifier: PMPL-1.0-or-later
# Justfile — infrastructure-automation
#
# Task runner for Ansible + Terraform infrastructure management.
# Homoiconic: each recipe name describes exactly what it does.
# Run `just` with no arguments to see all available recipes.

# Default recipe: show help
default:
    @just --list --unsorted

# ── Ansible ───────────────────────────────────────────────────

# Apply all configuration (full convergence)
apply:
    cd ansible && ansible-playbook playbooks/site.yml

# Dry run: show what would change without changing anything
check:
    cd ansible && ansible-playbook playbooks/site.yml --check --diff

# Apply only roles matching the given tag(s)
apply-tags tags:
    cd ansible && ansible-playbook playbooks/site.yml --tags "{{tags}}"

# Check only roles matching the given tag(s)
check-tags tags:
    cd ansible && ansible-playbook playbooks/site.yml --check --diff --tags "{{tags}}"

# Apply only base configuration (packages, users, files, services, networking)
apply-base:
    cd ansible && ansible-playbook playbooks/base.yml

# Apply only security configuration (firewall, sudo)
apply-security:
    cd ansible && ansible-playbook playbooks/security.yml

# Apply only monitoring configuration
apply-monitoring:
    cd ansible && ansible-playbook playbooks/monitoring.yml

# Apply only container configuration
apply-containers:
    cd ansible && ansible-playbook playbooks/containers.yml

# Apply only development tools
apply-dev:
    cd ansible && ansible-playbook playbooks/development.yml

# List all managed hosts
inventory:
    cd ansible && ansible-inventory --list --yaml

# Gather and display facts for localhost
facts:
    cd ansible && ansible localhost -m ansible.builtin.setup

# Test connectivity to all hosts
ping:
    cd ansible && ansible all -m ping

# Validate playbook syntax
lint:
    cd ansible && ansible-playbook playbooks/site.yml --syntax-check

# Install required Ansible collections
collections:
    ansible-galaxy collection install -r ansible/requirements.yml --force

# ── Terraform ─────────────────────────────────────────────────

# Initialise Terraform (download providers)
tf-init:
    cd terraform && terraform init

# Plan Terraform changes (dry run)
tf-plan:
    cd terraform && terraform plan

# Apply Terraform changes (provision containers)
tf-apply:
    cd terraform && terraform apply

# Destroy all Terraform-managed containers
tf-destroy:
    cd terraform && terraform destroy

# Show current Terraform state
tf-state:
    cd terraform && terraform show

# Output Terraform values (reflexive: query infrastructure state)
tf-output:
    cd terraform && terraform output -json

# ── Reflexive ─────────────────────────────────────────────────

# Run self-check: validate current vs desired state
self-check:
    ./scripts/self-check.sh

# Run self-check with JSON output
self-check-json:
    ./scripts/self-check.sh --json

# View the reflexive report from the last Ansible run
report:
    @if [ -f /tmp/ansible-reflexive-report.json ]; then \
        python3 -m json.tool /tmp/ansible-reflexive-report.json; \
    else \
        echo "No report found. Run 'just apply' first."; \
    fi

# ── Setup ─────────────────────────────────────────────────────

# First-time bootstrap (install Ansible, Terraform, collections)
bootstrap:
    ./scripts/bootstrap.sh

# Migration helper: check Salt state and prepare for migration
migrate:
    ./scripts/migrate-from-salt.sh

# ── Maintenance ───────────────────────────────────────────────

# Show what's changed since last git commit
status:
    @git status --short
    @echo ""
    @echo "Ansible roles:"
    @ls -1 ansible/roles/

# Validate all files (lint + syntax check)
validate: lint
    @echo "Validation passed."

# Run panic-attacker pre-commit scan
assail:
    @command -v panic-attack >/dev/null 2>&1 && panic-attack assail . || echo "panic-attack not found — install from https://github.com/hyperpolymath/panic-attacker"

# Self-diagnostic — checks dependencies, permissions, paths
doctor:
    @echo "Running diagnostics for infrastructure-automation..."
    @echo "Checking required tools..."
    @command -v just >/dev/null 2>&1 && echo "  [OK] just" || echo "  [FAIL] just not found"
    @command -v git >/dev/null 2>&1 && echo "  [OK] git" || echo "  [FAIL] git not found"
    @echo "Checking for hardcoded paths..."
    @grep -rn '$HOME\|$ECLIPSE_DIR' --include='*.rs' --include='*.ex' --include='*.res' --include='*.gleam' --include='*.sh' . 2>/dev/null | head -5 || echo "  [OK] No hardcoded paths"
    @echo "Diagnostics complete."

# Auto-repair common issues
heal:
    @echo "Attempting auto-repair for infrastructure-automation..."
    @echo "Fixing permissions..."
    @find . -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
    @echo "Cleaning stale caches..."
    @rm -rf .cache/stale 2>/dev/null || true
    @echo "Repair complete."

# Guided tour of key features
tour:
    @echo "=== infrastructure-automation Tour ==="
    @echo ""
    @echo "1. Project structure:"
    @ls -la
    @echo ""
    @echo "2. Available commands: just --list"
    @echo ""
    @echo "3. Read README.adoc for full overview"
    @echo "4. Read EXPLAINME.adoc for architecture decisions"
    @echo "5. Run 'just doctor' to check your setup"
    @echo ""
    @echo "Tour complete! Try 'just --list' to see all available commands."

# Open feedback channel with diagnostic context
help-me:
    @echo "=== infrastructure-automation Help ==="
    @echo "Platform: $(uname -s) $(uname -m)"
    @echo "Shell: $SHELL"
    @echo ""
    @echo "To report an issue:"
    @echo "  https://github.com/hyperpolymath/infrastructure-automation/issues/new"
    @echo ""
    @echo "Include the output of 'just doctor' in your report."


# Print the current CRG grade (reads from READINESS.md '**Current Grade:** X' line)
crg-grade:
    @grade=$$(grep -oP '(?<=\*\*Current Grade:\*\* )[A-FX]' READINESS.md 2>/dev/null | head -1); \
    [ -z "$$grade" ] && grade="X"; \
    echo "$$grade"

# Generate a shields.io badge markdown for the current CRG grade
# Looks for '**Current Grade:** X' in READINESS.md; falls back to X
crg-badge:
    @grade=$$(grep -oP '(?<=\*\*Current Grade:\*\* )[A-FX]' READINESS.md 2>/dev/null | head -1); \
    [ -z "$$grade" ] && grade="X"; \
    case "$$grade" in \
      A) color="brightgreen" ;; B) color="green" ;; C) color="yellow" ;; \
      D) color="orange" ;; E) color="red" ;; F) color="critical" ;; \
      *) color="lightgrey" ;; esac; \
    echo "[![CRG $$grade](https://img.shields.io/badge/CRG-$$grade-$$color?style=flat-square)](https://github.com/hyperpolymath/standards/tree/main/component-readiness-grades)"
