# SPDX-License-Identifier: MPL-2.0
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
