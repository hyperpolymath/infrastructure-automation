# SPDX-License-Identifier: PMPL-1.0-or-later
# Terraform Outputs — infrastructure-automation
#
# Reflexive: these outputs let the system describe its own current state.
#   terraform output -json
#   terraform output running_containers

output "running_containers" {
  description = "Map of all managed containers and their current state"
  value = {
    for name, container in docker_container.service : name => {
      id         = container.id
      name       = container.name
      image      = container.image
      ports      = container.ports
      networks   = container.network_data
      restart    = container.restart
      created    = true
    }
  }
}

output "managed_networks" {
  description = "Map of all managed container networks"
  value = {
    for name, network in docker_network.managed : name => {
      id     = network.id
      name   = network.name
      driver = network.driver
    }
  }
}

output "container_count" {
  description = "Number of containers currently managed by Terraform"
  value       = length(docker_container.service)
}

output "infrastructure_summary" {
  description = "Human-readable summary of managed infrastructure"
  value       = <<-EOT
    Infrastructure Automation — Terraform Layer
    ─────────────────────────────────────────────
    Project:    ${var.project_name}
    Containers: ${length(docker_container.service)}
    Networks:   ${length(docker_network.managed)}
    Provider:   Podman (via Docker-compatible API)
    Socket:     ${var.podman_socket}
  EOT
}
