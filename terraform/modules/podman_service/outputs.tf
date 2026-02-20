# SPDX-License-Identifier: PMPL-1.0-or-later
# Outputs for podman_service module

output "container_id" {
  description = "Container ID"
  value       = docker_container.this.id
}

output "container_name" {
  description = "Container name"
  value       = docker_container.this.name
}

output "container_ports" {
  description = "Mapped ports"
  value       = docker_container.this.ports
}

output "image_id" {
  description = "Image ID"
  value       = docker_image.this.image_id
}
