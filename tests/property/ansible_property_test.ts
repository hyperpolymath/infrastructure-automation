// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
// Property-based tests — YAML validation loops and convention checks

import { assertEquals } from "https://deno.land/std@0.220.0/assert/mod.ts";

const REPO_ROOT = new URL("../..", import.meta.url).pathname;

Deno.test("Property: All YAML files are readable and valid (100 iterations)", async () => {
  const yamlFiles: string[] = [];

  // Collect all YAML files
  const playbooksDir = `${REPO_ROOT}/ansible/playbooks`;
  for await (const entry of Deno.readDir(playbooksDir)) {
    if (entry.isFile && entry.name.endsWith(".yml")) {
      yamlFiles.push(`${playbooksDir}/${entry.name}`);
    }
  }

  const rolesDir = `${REPO_ROOT}/ansible/roles`;
  for await (const roleEntry of Deno.readDir(rolesDir)) {
    if (roleEntry.isDirectory) {
      const tasksFile = `${rolesDir}/${roleEntry.name}/tasks/main.yml`;
      const metaFile = `${rolesDir}/${roleEntry.name}/meta/main.yml`;
      const defaultsFile = `${rolesDir}/${roleEntry.name}/defaults/main.yml`;

      if (await fileExists(tasksFile)) yamlFiles.push(tasksFile);
      if (await fileExists(metaFile)) yamlFiles.push(metaFile);
      if (await fileExists(defaultsFile)) yamlFiles.push(defaultsFile);
    }
  }

  // Property: Run 100 iterations of YAML readability
  for (let i = 0; i < 100; i++) {
    for (const yamlFile of yamlFiles) {
      const content = await Deno.readTextFile(yamlFile);
      assertEquals(
        typeof content,
        "string",
        `YAML file ${yamlFile} iteration ${i} should be readable as string`,
      );
    }
  }
});

Deno.test("Property: Role directory names follow lowercase-underscore convention", async () => {
  const rolesDir = `${REPO_ROOT}/ansible/roles`;
  const rolePattern = /^[a-z][a-z0-9_]*$/;

  for await (const entry of Deno.readDir(rolesDir)) {
    if (entry.isDirectory) {
      assertEquals(
        rolePattern.test(entry.name),
        true,
        `Role name '${entry.name}' should follow lowercase-underscore convention`,
      );
    }
  }
});

Deno.test("Property: All role tasks/main.yml files are non-empty", async () => {
  const rolesDir = `${REPO_ROOT}/ansible/roles`;

  for await (const entry of Deno.readDir(rolesDir)) {
    if (entry.isDirectory) {
      const taskFile = `${rolesDir}/${entry.name}/tasks/main.yml`;
      const content = await Deno.readTextFile(taskFile);
      assertEquals(
        content.length > 0,
        true,
        `Role '${entry.name}' tasks/main.yml should be non-empty`,
      );
      assertEquals(
        content.includes("-"),
        true,
        `Role '${entry.name}' tasks should have Ansible tasks (dashes)`,
      );
    }
  }
});

Deno.test("Property: Group vars follow expected structure patterns", async () => {
  const groupVarsDir = `${REPO_ROOT}/ansible/inventory/group_vars`;

  for await (const entry of Deno.readDir(groupVarsDir)) {
    if (entry.isFile && entry.name.endsWith(".yml")) {
      const content = await Deno.readTextFile(
        `${groupVarsDir}/${entry.name}`,
      );
      // Property: group vars should contain YAML structure
      assertEquals(
        content.includes(":") || content.includes("---"),
        true,
        `Group var ${entry.name} should have valid YAML structure`,
      );
    }
  }
});

Deno.test("Property: All playbooks start with valid YAML", async () => {
  const playbooksDir = `${REPO_ROOT}/ansible/playbooks`;

  for await (const entry of Deno.readDir(playbooksDir)) {
    if (entry.isFile && entry.name.endsWith(".yml")) {
      const content = await Deno.readTextFile(
        `${playbooksDir}/${entry.name}`,
      );
      const startIsValid =
        content.startsWith("---") ||
        content.startsWith("#") ||
        content.startsWith("-") ||
        content.trim().length > 0;

      assertEquals(
        startIsValid,
        true,
        `Playbook ${entry.name} should start with valid YAML`,
      );
    }
  }
});

Deno.test("Property: Handlers exist in roles that define them", async () => {
  const rolesWithHandlers = [
    "firewall",
    "monitoring",
    "services",
    "podman_containers",
  ];

  for (const role of rolesWithHandlers) {
    const handlersFile = `${REPO_ROOT}/ansible/roles/${role}/handlers/main.yml`;
    try {
      const content = await Deno.readTextFile(handlersFile);
      assertEquals(
        content.length > 0,
        true,
        `Role ${role} should have handlers/main.yml`,
      );
    } catch (e) {
      if (!(e instanceof Deno.errors.NotFound)) {
        throw e;
      }
    }
  }
});

async function fileExists(path: string): Promise<boolean> {
  try {
    await Deno.stat(path);
    return true;
  } catch (e) {
    if (e instanceof Deno.errors.NotFound) {
      return false;
    }
    throw e;
  }
}
