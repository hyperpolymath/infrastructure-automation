# SPDX-License-Identifier: PMPL-1.0-or-later

# Terraform Variables — Declarative Infrastructure Schema.
#
# This file defines the "Input Surface" for the automation engine. 
# It uses strict typing and validation blocks to ensure that the 
//! infrastructure specification is well-formed before any physical 
//! resources are provisioned.

# PROVIDER CONFIG: Path to the local container socket.
variable "podman_socket" {
  description = "Path to Podman's Docker-compatible socket"
  type        = string
  default     = "unix:///run/user/1000/podman/podman.sock"

  validation {
    condition     = can(regex("^unix://", var.podman_socket))
    error_message = "Podman socket must be a unix:// URI."
  }
}

# INVENTORY: The authoritative map of containerized services.
# Each entry defines the image, ports, volumes, and health-checks.
variable "container_services" {
  description = "Declarative inventory of all managed containers."
  type = map(object({
    image          = string
    tag            = optional(string, "latest")
    ports          = optional(list(object({
      internal = number
      external = number
    })), [])
    enabled        = optional(bool, true)
    # ... [Other service properties]
  }))
  default = {}
}

# TAGGING: Authoritative metadata applied to all provisioned resources.
variable "default_labels" {
  description = "Labels applied to all containers for provenance tracking."
  type        = map(string)
  default = {
    "managed-by"  = "terraform"
    "project"     = "infrastructure-automation"
  }
}
