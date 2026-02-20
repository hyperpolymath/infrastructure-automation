; SPDX-License-Identifier: PMPL-1.0-or-later
; META.scm — Meta-level information for infrastructure-automation

(meta
  (version "1.0.0")

  (architecture-decisions
    (adr "ADR-001" "Use Ansible for configuration management"
      (status "accepted")
      (context "Migrating from SaltStack. Need configuration management for
                packages, users, files, services, firewall, monitoring on local systems.")
      (decision "Ansible is the direct SaltStack replacement. It uses agentless SSH,
                 has a massive module ecosystem, and YAML playbooks are homoiconic —
                 the configuration IS the program.")
      (consequences "Requires Python on managed hosts. No persistent agent (advantage
                     on immutable OS). Larger community than Salt."))

    (adr "ADR-002" "Use Terraform only for container provisioning"
      (status "accepted")
      (context "User preference was 'ideally terraform for everything' but Terraform
                is designed for infrastructure provisioning, not configuration management.")
      (decision "Terraform manages Podman containers via kreuzwerker/docker provider
                 (Podman exposes Docker-compatible API). Ansible handles everything else.")
      (consequences "Clean separation of concerns. Terraform state tracks container
                     lifecycle. Ansible handles host configuration."))

    (adr "ADR-003" "Reflexive self-inspection pattern"
      (status "accepted")
      (context "System should be able to inspect and report its own state —
                reflexive property.")
      (decision "Custom Ansible callback plugin (reflexive_reporter) logs all
                 changes. scripts/self-check.sh validates current vs desired state.
                 Ansible facts provide runtime introspection.")
      (consequences "Slight overhead from callback plugin. Significant observability gain."))

    (adr "ADR-004" "Homoiconic configuration design"
      (status "accepted")
      (context "Configuration should describe itself — the map IS the territory.")
      (decision "Each Ansible role carries its own metadata in meta/main.yml
                 describing purpose, dependencies, and capabilities. Variables in
                 defaults/main.yml are self-documenting with comments. The playbook
                 structure mirrors the system architecture.")
      (consequences "Roles are self-contained and self-describing. New contributors
                     can understand any role by reading its meta/ and defaults/."))

    (adr "ADR-005" "Fedora Silverblue immutable OS adaptations"
      (status "accepted")
      (context "Silverblue uses rpm-ostree (immutable root). Standard package
                management (dnf/yum) doesn't work on the host.")
      (decision "Use rpm-ostree for host packages (silverblue role). Use Podman
                 containers for services that need mutable filesystems. Use toolbox
                 for development environments.")
      (consequences "Some Ansible modules (yum, dnf) won't work directly.
                     Custom tasks use command module with rpm-ostree.")))

  (development-practices
    (testing "Ansible check mode (--check --diff) for dry runs")
    (testing "scripts/self-check.sh for state validation")
    (ci-cd "GitHub Actions for linting and validation")
    (versioning "Semantic versioning for releases")
    (documentation "AsciiDoc for primary docs, YAML comments for inline"))

  (design-rationale
    (philosophy "Infrastructure should be transparent, self-describing, and
                 reversible. Every change must be auditable and every state
                 queryable. The system's documentation IS its implementation.")))
