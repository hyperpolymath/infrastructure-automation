; SPDX-License-Identifier: PMPL-1.0-or-later
; STATE.scm — Current project state for infrastructure-automation

(state
  (metadata
    (version "1.0.0")
    (last-updated "2026-02-20")
    (author "Jonathan D.A. Jewell <jonathan.jewell@open.ac.uk>"))

  (project-context
    (name "infrastructure-automation")
    (description "SaltStack to Ansible + Terraform migration for local infrastructure")
    (phase "initial-release")
    (target-platform "Fedora Silverblue 43 (Atomic Desktop)"))

  (current-position
    (overall-completion 100)
    (components
      (ansible-roles 100 "11 roles covering all Salt state equivalents")
      (ansible-playbooks 100 "site.yml orchestration with modular playbooks")
      (ansible-inventory 100 "Local hosts with group_vars")
      (terraform-podman 100 "Podman container provisioning module")
      (documentation 100 "Architecture, migration guide, quickstart, decision log")
      (scripts 100 "Bootstrap, self-check, migration helper")
      (reflexive-plugin 100 "Ansible callback for self-inspection")
      (justfile 100 "All automation recipes")))

  (route-to-mvp
    (milestone "v1.0.0" "Initial release"
      (status "complete")
      (deliverables
        "Ansible roles for all Salt states"
        "Terraform Podman provisioning"
        "Reflexive self-check system"
        "Comprehensive documentation"
        "Migration guide from SaltStack")))

  (blockers-and-issues
    (none))

  (critical-next-actions
    (action "Test on target Silverblue host")
    (action "Add vault-encrypted secrets for production")
    (action "Integrate with HAR for multi-format routing")
    (action "Add CI/CD pipeline via GitHub Actions")))
