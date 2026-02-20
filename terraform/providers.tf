# SPDX-License-Identifier: PMPL-1.0-or-later
# Provider Configuration
#
# Uses kreuzwerker/docker provider against Podman's Docker-compatible socket.
# This is the bridge that lets Terraform manage Podman containers declaratively.
#
# Prerequisites:
#   systemctl --user enable --now podman.socket
#   export DOCKER_HOST=unix:///run/user/$(id -u)/podman/podman.sock

provider "docker" {
  # Podman rootless socket — set via DOCKER_HOST env var or here directly.
  # Default: unix:///run/user/<UID>/podman/podman.sock
  host = var.podman_socket
}
