# SPDX-License-Identifier: PMPL-1.0-or-later
# Podman Service Module — reusable container service definition
#
# This module encapsulates a single container service with:
#   - Image pull and lifecycle management
#   - Port mapping, volume mounts, environment
#   - Health checking
#   - Systemd integration for rootless Podman

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

resource "docker_image" "this" {
  name         = "${var.image}:${var.tag}"
  keep_locally = true
}

resource "docker_container" "this" {
  name    = var.name
  image   = docker_image.this.image_id
  restart = var.restart_policy

  dynamic "ports" {
    for_each = var.ports
    content {
      internal = ports.value.internal
      external = ports.value.external
      protocol = lookup(ports.value, "protocol", "tcp")
    }
  }

  dynamic "volumes" {
    for_each = var.volumes
    content {
      host_path      = volumes.value.host_path
      container_path = volumes.value.container_path
      read_only      = lookup(volumes.value, "read_only", false)
    }
  }

  env = [for k, v in var.environment : "${k}=${v}"]

  dynamic "healthcheck" {
    for_each = var.healthcheck_command != null ? [1] : []
    content {
      test     = var.healthcheck_command
      interval = var.healthcheck_interval
      timeout  = var.healthcheck_timeout
      retries  = var.healthcheck_retries
    }
  }

  labels {
    label = "managed-by"
    value = "terraform"
  }
  labels {
    label = "module"
    value = "podman_service"
  }

  lifecycle {
    create_before_destroy = true
  }
}
