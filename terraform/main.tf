# SPDX-License-Identifier: PMPL-1.0-or-later
# Main Terraform Configuration — infrastructure-automation
#
# Declarative container provisioning via Podman.
# Terraform manages container LIFECYCLE (create, update, destroy).
# Ansible manages container CONFIGURATION (what runs inside).
#
# Homoiconic: the container_services variable IS the infrastructure.
#   Add a service → Terraform creates it.
#   Remove a service → Terraform destroys it.
#   Change a property → Terraform updates it.
#
# Reflexive: outputs expose current state for inspection.
#   terraform output -json | jq '.running_containers'

# ── Networks ──────────────────────────────────────────────────

resource "docker_network" "managed" {
  for_each = var.networks

  name   = "${var.project_name}-${each.key}"
  driver = each.value.driver

  dynamic "ipam_config" {
    for_each = each.value.subnet != "" ? [1] : []
    content {
      subnet  = each.value.subnet
      gateway = each.value.gateway
    }
  }

  labels {
    label = "managed-by"
    value = "terraform"
  }

  labels {
    label = "project"
    value = var.project_name
  }
}

# ── Container Images ──────────────────────────────────────────

resource "docker_image" "service" {
  for_each = {
    for name, svc in var.container_services : name => svc
    if svc.enabled
  }

  name         = "${each.value.image}:${each.value.tag}"
  keep_locally = true
}

# ── Containers ────────────────────────────────────────────────

resource "docker_container" "service" {
  for_each = {
    for name, svc in var.container_services : name => svc
    if svc.enabled
  }

  name    = "${var.project_name}-${each.key}"
  image   = docker_image.service[each.key].image_id
  restart = each.value.restart

  # Port mappings
  dynamic "ports" {
    for_each = each.value.ports
    content {
      internal = ports.value.internal
      external = ports.value.external
      protocol = ports.value.protocol
    }
  }

  # Volume mounts
  dynamic "volumes" {
    for_each = each.value.volumes
    content {
      host_path      = volumes.value.host_path
      container_path = volumes.value.container_path
      read_only      = volumes.value.read_only
    }
  }

  # Environment variables
  env = [
    for k, v in merge(
      { "MANAGED_BY" = "terraform", "SERVICE_NAME" = each.key },
      each.value.env
    ) : "${k}=${v}"
  ]

  # Health check
  dynamic "healthcheck" {
    for_each = each.value.healthcheck != null ? [each.value.healthcheck] : []
    content {
      test     = healthcheck.value.test
      interval = healthcheck.value.interval
      timeout  = healthcheck.value.timeout
      retries  = healthcheck.value.retries
    }
  }

  # Labels (merge defaults with service-specific)
  dynamic "labels" {
    for_each = merge(var.default_labels, each.value.labels, {
      "service" = each.key
    })
    content {
      label = labels.key
      value = labels.value
    }
  }

  # Network connections
  dynamic "networks_advanced" {
    for_each = each.value.networks
    content {
      name = docker_network.managed[networks_advanced.value].name
    }
  }

  # Resource limits
  memory = each.value.memory_limit > 0 ? each.value.memory_limit : null

  # Ensure image is pulled before container creation
  depends_on = [docker_image.service]

  lifecycle {
    # Prevent accidental destruction of data containers
    # Remove this block if you want Terraform to freely recreate containers
    create_before_destroy = true
  }
}
