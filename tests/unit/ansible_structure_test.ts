// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
// Unit tests — Ansible playbook and role structure validation

import { assertEquals } from "https://deno.land/std@0.220.0/assert/mod.ts";

const REPO_ROOT = new URL("../..", import.meta.url).pathname;

Deno.test("Unit: All playbook files exist", async () => {
  const playbooks = [
    "site.yml",
    "base.yml",
    "security.yml",
    "monitoring.yml",
    "containers.yml",
    "development.yml",
  ];

  for (const playbook of playbooks) {
    const path = `${REPO_ROOT}/ansible/playbooks/${playbook}`;
    const stat = await Deno.stat(path);
    assertEquals(stat.isFile, true, `Playbook ${playbook} should exist`);
  }
});

Deno.test("Unit: All critical roles exist", async () => {
  const roles = [
    "base_packages",
    "users",
    "firewall",
    "services",
    "monitoring",
    "sudo_config",
    "files_managed",
    "development",
    "networking",
    "podman_containers",
    "silverblue",
  ];

  for (const role of roles) {
    const path = `${REPO_ROOT}/ansible/roles/${role}`;
    const stat = await Deno.stat(path);
    assertEquals(stat.isDirectory, true, `Role directory ${role} should exist`);
  }
});

Deno.test("Unit: All roles have tasks/main.yml", async () => {
  const rolesDir = `${REPO_ROOT}/ansible/roles`;
  for await (const entry of Deno.readDir(rolesDir)) {
    if (entry.isDirectory) {
      const taskFile = `${rolesDir}/${entry.name}/tasks/main.yml`;
      const stat = await Deno.stat(taskFile);
      assertEquals(
        stat.isFile,
        true,
        `Role ${entry.name} should have tasks/main.yml`,
      );
    }
  }
});

Deno.test("Unit: Inventory files exist", async () => {
  const inventory = `${REPO_ROOT}/ansible/inventory/hosts.yml`;
  const stat = await Deno.stat(inventory);
  assertEquals(stat.isFile, true, "Inventory hosts.yml should exist");

  const groupVars = `${REPO_ROOT}/ansible/inventory/group_vars`;
  const gvStat = await Deno.stat(groupVars);
  assertEquals(gvStat.isDirectory, true, "group_vars directory should exist");
});

Deno.test("Unit: Playbook files are non-empty YAML", async () => {
  const playbooks = [
    "site.yml",
    "base.yml",
    "security.yml",
    "monitoring.yml",
    "containers.yml",
    "development.yml",
  ];

  for (const playbook of playbooks) {
    const path = `${REPO_ROOT}/ansible/playbooks/${playbook}`;
    const content = await Deno.readTextFile(path);
    assertEquals(content.length > 0, true, `${playbook} should not be empty`);
    assertEquals(
      content.includes("---") || content.includes(":"),
      true,
      `${playbook} should have YAML markers`,
    );
  }
});

Deno.test("Unit: All role tasks are non-empty", async () => {
  const rolesDir = `${REPO_ROOT}/ansible/roles`;
  for await (const entry of Deno.readDir(rolesDir)) {
    if (entry.isDirectory) {
      const taskFile = `${rolesDir}/${entry.name}/tasks/main.yml`;
      const content = await Deno.readTextFile(taskFile);
      assertEquals(
        content.length > 0,
        true,
        `Role ${entry.name} tasks should not be empty`,
      );
    }
  }
});

Deno.test("Unit: All roles have meta/main.yml", async () => {
  const rolesDir = `${REPO_ROOT}/ansible/roles`;
  for await (const entry of Deno.readDir(rolesDir)) {
    if (entry.isDirectory) {
      const metaFile = `${rolesDir}/${entry.name}/meta/main.yml`;
      const stat = await Deno.stat(metaFile);
      assertEquals(
        stat.isFile,
        true,
        `Role ${entry.name} should have meta/main.yml`,
      );
    }
  }
});

Deno.test("Unit: ansible.cfg exists", async () => {
  const ansibleCfg = `${REPO_ROOT}/ansible/ansible.cfg`;
  const stat = await Deno.stat(ansibleCfg);
  assertEquals(stat.isFile, true, "ansible.cfg should exist");
});
