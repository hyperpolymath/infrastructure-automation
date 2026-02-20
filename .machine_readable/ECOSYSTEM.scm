; SPDX-License-Identifier: PMPL-1.0-or-later
; ECOSYSTEM.scm — Ecosystem position for infrastructure-automation

(ecosystem
  (version "1.0.0")
  (name "infrastructure-automation")
  (type "infrastructure-as-code")
  (purpose "Replace SaltStack with modern Ansible + Terraform for local infrastructure management")

  (position-in-ecosystem
    (role "core-infrastructure")
    (description "Primary IaC repository for all hyperpolymath local infrastructure.
                  Manages system configuration (Ansible) and container provisioning
                  (Terraform) on Fedora Silverblue immutable OS."))

  (related-projects
    (project "hybrid-automation-router"
      (relationship "consumer")
      (description "HAR can parse these Ansible/Terraform configs and route to other formats")
      (direction "infrastructure-automation -> HAR"))

    (project "ambientops"
      (relationship "sibling-standard")
      (description "Ambient operations framework — this repo implements its infrastructure layer")
      (direction "bidirectional"))

    (project "http-capability-gateway"
      (relationship "deployment-target")
      (description "Gateway deployed and configured via these playbooks and Terraform")
      (direction "infrastructure-automation -> http-capability-gateway"))

    (project "gitbot-fleet"
      (relationship "potential-consumer")
      (description "Bot fleet infrastructure could be managed by these playbooks")
      (direction "infrastructure-automation -> gitbot-fleet"))

    (project "saltstack (legacy)"
      (relationship "supersedes")
      (description "This repo completely replaces the containerized Salt setup")
      (direction "replaces")))

  (technology-stack
    (primary "Ansible 2.16+" "Configuration management")
    (primary "Terraform 1.7+" "Container provisioning")
    (runtime "Podman 5.x" "Container runtime (rootless)")
    (target-os "Fedora Silverblue 43" "Immutable desktop OS")
    (scripting "Bash/POSIX" "Bootstrap and helper scripts"))

  (standards-compliance
    (rsr "Rhodium Standard Repositories")
    (cis "CIS Benchmark alignment for firewall and sudo")
    (openssf "OpenSSF Scorecard compatible")))
