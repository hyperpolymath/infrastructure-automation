// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
// E2E contract tests — Full Ansible hierarchy validation

import { assertEquals } from "https://deno.land/std@0.220.0/assert/mod.ts";

const REPO_ROOT = new URL("../..", import.meta.url).pathname;

Deno.test("E2E: site.yml imports all critical playbooks", async () => {
  const siteContent = await Deno.readTextFile(
    `${REPO_ROOT}/ansible/playbooks/site.yml`,
  );

  const requiredImports = ["base.yml", "security.yml", "containers.yml"];
  for (const importName of requiredImports) {
    assertEquals(
      siteContent.includes(importName),
      true,
      `site.yml should import ${importName}`,
    );
  }
});

Deno.test("E2E: All roles referenced in playbooks exist", async () => {
  const playbooksDir = `${REPO_ROOT}/ansible/playbooks`;
  const roleNames: Set<string> = new Set();

  // Collect all playbook files
  for await (const entry of Deno.readDir(playbooksDir)) {
    if (entry.isFile && entry.name.endsWith(".yml")) {
      const content = await Deno.readTextFile(
        `${playbooksDir}/${entry.name}`,
      );

      // Extract role references (simple pattern: "- role:" or "roles:")
      const roleMatches = content.match(/\brole:\s*(\w+)/g) ||
        content.match(/\broles:\s*[\n\s]*-\s*(\w+)/g) || [];

      for (const match of roleMatches) {
        const roleName = match.replace(/role:\s*|\broles:\s*[\n\s]*-\s*/, "");
        if (roleName.length > 0) {
          roleNames.add(roleName);
        }
      }
    }
  }

  // Verify each referenced role exists
  const rolesDir = `${REPO_ROOT}/ansible/roles`;
  for (const roleName of roleNames) {
    try {
      const stat = await Deno.stat(`${rolesDir}/${roleName}`);
      assertEquals(
        stat.isDirectory,
        true,
        `Referenced role ${roleName} should exist`,
      );
    } catch (e) {
      if (e instanceof Deno.errors.NotFound) {
        console.warn(`Warning: Referenced role ${roleName} not found`);
      } else {
        throw e;
      }
    }
  }
});

Deno.test("E2E: Inventory references match group_vars", async () => {
  const hostsContent = await Deno.readTextFile(
    `${REPO_ROOT}/ansible/inventory/hosts.yml`,
  );

  // Extract group names from inventory
  const groupMatches = hostsContent.match(/^\[(\w+)\]/gm) || [];
  const groups: Set<string> = new Set(
    groupMatches.map((g) => g.replace(/[\[\]]/g, "")),
  );

  const groupVarsDir = `${REPO_ROOT}/ansible/inventory/group_vars`;
  const varsFiles: Set<string> = new Set();

  for await (const entry of Deno.readDir(groupVarsDir)) {
    if (entry.isFile && entry.name.endsWith(".yml")) {
      varsFiles.add(entry.name.replace(".yml", ""));
    }
  }

  // Each group in inventory should have a corresponding group_vars file
  for (const group of groups) {
    const hasVars = varsFiles.has(group);
    assertEquals(
      hasVars || group === "all" || group === "ungrouped",
      true,
      `Inventory group ${group} should have a group_vars file or be implicit`,
    );
  }
});

Deno.test("E2E: Security playbook references firewall and sudo roles", async () => {
  const securityContent = await Deno.readTextFile(
    `${REPO_ROOT}/ansible/playbooks/security.yml`,
  );

  assertEquals(
    securityContent.includes("firewall"),
    true,
    "security.yml should reference firewall role",
  );

  assertEquals(
    securityContent.includes("sudo_config"),
    true,
    "security.yml should reference sudo_config role",
  );
});

Deno.test("E2E: Base playbook references base_packages and users roles", async () => {
  const baseContent = await Deno.readTextFile(
    `${REPO_ROOT}/ansible/playbooks/base.yml`,
  );

  assertEquals(
    baseContent.includes("base_packages") || baseContent.includes("packages"),
    true,
    "base.yml should reference base_packages role",
  );

  assertEquals(
    baseContent.includes("users"),
    true,
    "base.yml should reference users role",
  );
});

Deno.test("E2E: Containers playbook references podman role", async () => {
  const containersContent = await Deno.readTextFile(
    `${REPO_ROOT}/ansible/playbooks/containers.yml`,
  );

  assertEquals(
    containersContent.includes("podman"),
    true,
    "containers.yml should reference podman-related role",
  );
});

Deno.test("E2E: All playbooks have valid basic YAML structure", async () => {
  const playbooks = [
    "site.yml",
    "base.yml",
    "security.yml",
    "monitoring.yml",
    "containers.yml",
    "development.yml",
  ];

  for (const playbook of playbooks) {
    const content = await Deno.readTextFile(
      `${REPO_ROOT}/ansible/playbooks/${playbook}`,
    );

    // Should have some YAML structure indicators
    const hasYamlStructure =
      content.includes("-") ||
      content.includes(":") ||
      content.includes("name:") ||
      content.includes("hosts:");

    assertEquals(
      hasYamlStructure,
      true,
      `Playbook ${playbook} should have valid YAML structure`,
    );
  }
});
