# SPDX-License-Identifier: PMPL-1.0-or-later
# Local Environment — Podman container provisioning
#
# This file demonstrates using the podman_service module
# for individual service definitions. For bulk provisioning,
# use the root module with container_services variable instead.

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }

  # Local state — no remote backend needed for local infrastructure
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "docker" {
  host = "unix:///run/user/1000/podman/podman.sock"
}

# Example: deploy nginx via the reusable module
# module "nginx" {
#   source = "../../modules/podman_service"
#
#   name  = "local-nginx"
#   image = "docker.io/library/nginx"
#   tag   = "alpine"
#
#   ports = [
#     { internal = 80, external = 8080 }
#   ]
#
#   healthcheck_command = ["CMD", "wget", "--spider", "-q", "http://localhost/"]
# }
