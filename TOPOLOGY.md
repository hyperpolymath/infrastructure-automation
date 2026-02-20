# TOPOLOGY — infrastructure-automation

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    infrastructure-automation                        │
│                                                                     │
│  ┌─────────────────────────────┐  ┌──────────────────────────────┐ │
│  │        ANSIBLE              │  │        TERRAFORM             │ │
│  │   (Config Management)       │  │   (Container Provisioning)   │ │
│  │                             │  │                              │ │
│  │  ┌───────────────────────┐  │  │  ┌────────────────────────┐ │ │
│  │  │    Playbooks          │  │  │  │    Providers           │ │ │
│  │  │  site.yml ─┐          │  │  │  │  kreuzwerker/docker    │ │ │
│  │  │    ├─ base.yml        │  │  │  │  (Podman-compatible)   │ │ │
│  │  │    ├─ security.yml    │  │  │  └────────────────────────┘ │ │
│  │  │    ├─ monitoring.yml  │  │  │                              │ │
│  │  │    ├─ containers.yml  │  │  │  ┌────────────────────────┐ │ │
│  │  │    └─ development.yml │  │  │  │    Modules             │ │ │
│  │  └───────────────────────┘  │  │  │  podman_service/       │ │ │
│  │                             │  │  └────────────────────────┘ │ │
│  │  ┌───────────────────────┐  │  │                              │ │
│  │  │    Roles (11)         │  │  │  ┌────────────────────────┐ │ │
│  │  │  base_packages ───────┼──┼──┤  │    State               │ │ │
│  │  │  users                │  │  │  │  terraform.tfstate     │ │ │
│  │  │  files_managed        │  │  │  │  (container lifecycle) │ │ │
│  │  │  services             │  │  │  └────────────────────────┘ │ │
│  │  │  firewall             │  │  │                              │ │
│  │  │  sudo_config          │  │  └──────────────────────────────┘ │
│  │  │  monitoring           │  │                                    │
│  │  │  networking           │  │  ┌──────────────────────────────┐ │
│  │  │  podman_containers    │  │  │     REFLEXIVE LAYER          │ │
│  │  │  silverblue           │  │  │  callback/reflexive_reporter │ │
│  │  │  development          │  │  │  scripts/self-check.sh       │ │
│  │  └───────────────────────┘  │  │  (system inspects itself)    │ │
│  │                             │  └──────────────────────────────┘ │
│  │  ┌───────────────────────┐  │                                    │
│  │  │    Inventory          │  │  ┌──────────────────────────────┐ │
│  │  │  hosts.yml            │  │  │     INTEGRATION              │ │
│  │  │  group_vars/all.yml   │  │  │  hybrid-automation-router    │ │
│  │  │  group_vars/silver*.  │  │  │  (IaC format translation)    │ │
│  │  └───────────────────────┘  │  └──────────────────────────────┘ │
│  └─────────────────────────────┘                                    │
└─────────────────────────────────────────────────────────────────────┘
          │                              │
          ▼                              ▼
┌──────────────────┐          ┌──────────────────┐
│  Fedora Silver-  │          │  Podman Contain-  │
│  blue Host       │          │  ers (rootless)   │
│  (immutable OS)  │          │                   │
│                  │          │  nginx, grafana,  │
│  rpm-ostree      │          │  custom services  │
│  systemd         │          │                   │
│  firewalld       │          │  Managed via      │
│  users/groups    │          │  Docker-compat API │
└──────────────────┘          └──────────────────┘
```

## Completion Dashboard

```
Component               Progress
────────────────────────────────────────────────
Ansible Roles           [██████████] 100%  11/11 roles
Ansible Playbooks       [██████████] 100%  6 playbooks
Ansible Inventory       [██████████] 100%  hosts + group_vars
Terraform Modules       [██████████] 100%  root + podman_service
Terraform Environments  [██████████] 100%  local environment
Reflexive Plugin        [██████████] 100%  callback reporter
Documentation           [██████████] 100%  5 docs
Scripts                 [██████████] 100%  3 scripts
Justfile                [██████████] 100%  all recipes
RSR Compliance          [██████████] 100%  SCM + manifest + template
────────────────────────────────────────────────
Overall                 [██████████] 100%
```

## Key Dependencies

```
Salt → Ansible Role Mapping
────────────────────────────────────
Salt State              Ansible Role
────────────────────────────────────
packages.sls         →  base_packages
users.sls            →  users
files.sls            →  files_managed
services.sls         →  services
firewall.sls         →  firewall
sudo.sls             →  sudo_config
monitoring/init.sls  →  monitoring
networking/init.sls  →  networking
containers/init.sls  →  podman_containers
(silverblue-specific)→  silverblue
(dev environment)    →  development
────────────────────────────────────

Terraform ↔ Ansible Integration
────────────────────────────────────
Terraform provisions containers
  ↓ outputs container IPs/ports
Ansible configures container hosts
  ↓ handlers restart containers
Terraform tracks lifecycle state
────────────────────────────────────
```
