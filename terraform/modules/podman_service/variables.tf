# SPDX-License-Identifier: PMPL-1.0-or-later
# Variables for podman_service module

variable "name" {
  description = "Container name"
  type        = string
}

variable "image" {
  description = "Container image (without tag)"
  type        = string
}

variable "tag" {
  description = "Image tag"
  type        = string
  default     = "latest"
}

variable "ports" {
  description = "List of port mappings"
  type = list(object({
    internal = number
    external = number
    protocol = optional(string, "tcp")
  }))
  default = []
}

variable "volumes" {
  description = "List of volume mounts"
  type = list(object({
    host_path      = string
    container_path = string
    read_only      = optional(bool, false)
  }))
  default = []
}

variable "environment" {
  description = "Environment variables"
  type        = map(string)
  default     = {}
}

variable "restart_policy" {
  description = "Container restart policy"
  type        = string
  default     = "unless-stopped"
}

variable "healthcheck_command" {
  description = "Health check command (null to disable)"
  type        = list(string)
  default     = null
}

variable "healthcheck_interval" {
  description = "Health check interval"
  type        = string
  default     = "30s"
}

variable "healthcheck_timeout" {
  description = "Health check timeout"
  type        = string
  default     = "5s"
}

variable "healthcheck_retries" {
  description = "Health check retry count"
  type        = number
  default     = 3
}
