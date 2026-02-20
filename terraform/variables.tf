# SPDX-License-Identifier: PMPL-1.0-or-later
# Terraform Variables — infrastructure-automation
#
# Homoiconic: each variable describes itself via description and validation.
# The variable declarations ARE the documentation.

variable "podman_socket" {
  description = "Path to Podman's Docker-compatible socket"
  type        = string
  default     = "unix:///run/user/1000/podman/podman.sock"

  validation {
    condition     = can(regex("^unix://", var.podman_socket))
    error_message = "Podman socket must be a unix:// URI."
  }
}

variable "project_name" {
  description = "Project name used for resource naming and labels"
  type        = string
  default     = "infra"
}

variable "container_services" {
  description = <<-EOT
    Map of container services to provision.
    Each service defines an image, ports, volumes, and environment.
    This is the declarative inventory of all managed containers.
  EOT
  type = map(object({
    image          = string
    tag            = optional(string, "latest")
    ports          = optional(list(object({
      internal = number
      external = number
      protocol = optional(string, "tcp")
    })), [])
    volumes        = optional(list(object({
      host_path      = string
      container_path = string
      read_only      = optional(bool, false)
    })), [])
    env            = optional(map(string), {})
    restart        = optional(string, "unless-stopped")
    healthcheck    = optional(object({
      test     = list(string)
      interval = optional(string, "30s")
      timeout  = optional(string, "5s")
      retries  = optional(number, 3)
    }), null)
    labels         = optional(map(string), {})
    networks       = optional(list(string), [])
    memory_limit   = optional(number, 0)
    cpu_shares     = optional(number, 0)
    enabled        = optional(bool, true)
  }))
  default = {}
}

variable "networks" {
  description = "Container networks to create"
  type = map(object({
    driver  = optional(string, "bridge")
    subnet  = optional(string, "")
    gateway = optional(string, "")
    labels  = optional(map(string), {})
  }))
  default = {}
}

variable "default_labels" {
  description = "Labels applied to all containers for identification and management"
  type        = map(string)
  default = {
    "managed-by"  = "terraform"
    "project"     = "infrastructure-automation"
    "org"         = "hyperpolymath"
  }
}
