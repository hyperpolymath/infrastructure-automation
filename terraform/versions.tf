# SPDX-License-Identifier: PMPL-1.0-or-later
# Terraform Version Constraints
# infrastructure-automation — container provisioning layer

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    docker = {
      # kreuzwerker/docker provider works with Podman's Docker-compatible API.
      # Enable Podman socket: systemctl --user enable --now podman.socket
      # Podman exposes: unix:///run/user/$UID/podman/podman.sock
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}
