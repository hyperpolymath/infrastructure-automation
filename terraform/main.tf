# SPDX-License-Identifier: PMPL-1.0-or-later

# Infrastructure Automation — Terraform Orchestration Kernel.
#
# This configuration implements a declarative system for provisioning 
//! high-assurance container environments. It treats infrastructure as 
//! a "reflexive" system where the code state exactly mirrors the 
//! running system state.

# NETWORKING: Defines the virtual topology for inter-container communication.
resource "docker_network" "managed" {
  for_each = var.networks
  name     = "${var.project_name}-${each.key}"
  driver   = each.value.driver
  # ... [IPAM and labeling logic]
}

# SERVICE DEFINITIONS: Generates container instances from the `container_services` map.
# Any change to the variables automatically triggers a plan/apply cycle to 
# reconcile the physical state with this declaration.
resource "docker_container" "service" {
  for_each = {
    for name, svc in var.container_services : name => svc
    if svc.enabled
  }

  name    = "${var.project_name}-${each.key}"
  image   = docker_image.service[each.key].image_id
  restart = each.value.restart

  # VOLUME MOUNTS: Persists data between container lifecycles.
  dynamic "volumes" {
    for_each = each.value.volumes
    content {
      host_path      = volumes.value.host_path
      container_path = volumes.value.container_path
      read_only      = volumes.value.read_only
    }
  }

  # LIFECYCLE: Ensures that data is never lost during updates by 
  # creating the new container before destroying the old one.
  lifecycle {
    create_before_destroy = true
  }
}
