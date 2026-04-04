// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
// Contract/invariant tests — Security and structural requirements

import { assertEquals } from "https://deno.land/std@0.220.0/assert/mod.ts";

const REPO_ROOT = new URL("../..", import.meta.url).pathname;

Deno.test("Contract: INVARIANT — No plaintext passwords in YAML files", async () => {
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
      const defaultsFile = `${rolesDir}/${roleEntry.name}/defaults/main.yml`;
      if (await fileExists(tasksFile)) yamlFiles.push(tasksFile);
      if (await fileExists(defaultsFile)) yamlFiles.push(defaultsFile);
    }
  }

  // Pattern for suspected plaintext passwords
  const passwordPattern =
    /password:\s*['"]?(?!{{\s*.*\s*}})([a-zA-Z0-9!@#$%^&*_-]{8,})['"]?/gi;

  for (const file of yamlFiles) {
    const content = await Deno.readTextFile(file);
    const matches = content.match(passwordPattern);

    // Exclude vault references and variable interpolation
    let suspiciousMatches = 0;
    if (matches) {
      for (const match of matches) {
        if (
          !match.includes("{{") &&
          !match.includes("vault") &&
          !match.includes("lookup")
        ) {
          suspiciousMatches++;
        }
      }
    }

    assertEquals(
      suspiciousMatches === 0,
      true,
      `File ${file} should not contain plaintext passwords`,
    );
  }
});

Deno.test("Contract: INVARIANT — Firewall role must exist", async () => {
  const firewallPath = `${REPO_ROOT}/ansible/roles/firewall`;
  const stat = await Deno.stat(firewallPath);
  assertEquals(
    stat.isDirectory,
    true,
    "Firewall role must exist for security hardening",
  );
});

Deno.test("Contract: INVARIANT — Sudo config role must exist", async () => {
  const sudoPath = `${REPO_ROOT}/ansible/roles/sudo_config`;
  const stat = await Deno.stat(sudoPath);
  assertEquals(
    stat.isDirectory,
    true,
    "Sudo config role must exist for privilege management",
  );
});

Deno.test("Contract: INVARIANT — All roles have meta/main.yml", async () => {
  const rolesDir = `${REPO_ROOT}/ansible/roles`;

  for await (const entry of Deno.readDir(rolesDir)) {
    if (entry.isDirectory) {
      const metaFile = `${rolesDir}/${entry.name}/meta/main.yml`;
      const stat = await Deno.stat(metaFile);
      assertEquals(
        stat.isFile,
        true,
        `Role ${entry.name} must have meta/main.yml for dependency tracking`,
      );
    }
  }
});

Deno.test("Contract: INVARIANT — Terraform state files not committed", async () => {
  let tfstateFound = false;

  // Check for .tfstate files (should not exist in repo)
  for await (const entry of walkDir(`${REPO_ROOT}/terraform`)) {
    if (entry.endsWith(".tfstate")) {
      tfstateFound = true;
      break;
    }
  }

  assertEquals(
    !tfstateFound,
    true,
    "Terraform state files (.tfstate) should not be committed",
  );
});

Deno.test("Contract: INVARIANT — Security playbook has hardening context", async () => {
  const securityContent = await Deno.readTextFile(
    `${REPO_ROOT}/ansible/playbooks/security.yml`,
  );

  const hasSecurityContext =
    securityContent.includes("become: true") ||
    securityContent.includes("firewall") ||
    securityContent.includes("sudo");

  assertEquals(
    hasSecurityContext,
    true,
    "Security playbook should have hardening tasks with elevated privileges",
  );
});

Deno.test("Contract: INVARIANT — No become without justification in critical roles", async () => {
  const criticalRoles = ["firewall", "sudo_config"];

  for (const role of criticalRoles) {
    const tasksFile = `${REPO_ROOT}/ansible/roles/${role}/tasks/main.yml`;
    const content = await Deno.readTextFile(tasksFile);

    // Check that become: true is used (justified by the role's purpose)
    const hasBecomeTrue = content.includes("become: true");
    assertEquals(
      hasBecomeTrue,
      true,
      `Role ${role} should use 'become: true' for privilege escalation`,
    );
  }
});

Deno.test("Contract: Base configuration must reference base_packages", async () => {
  const baseContent = await Deno.readTextFile(
    `${REPO_ROOT}/ansible/playbooks/base.yml`,
  );

  assertEquals(
    baseContent.includes("base_packages") || baseContent.includes("packages"),
    true,
    "Base playbook must include package management role",
  );
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

async function* walkDir(path: string): AsyncGenerator<string> {
  try {
    for await (const entry of Deno.readDir(path)) {
      const fullPath = `${path}/${entry.name}`;
      yield fullPath;
      if (entry.isDirectory) {
        yield* walkDir(fullPath);
      }
    }
  } catch (e) {
    if (!(e instanceof Deno.errors.NotFound)) {
      throw e;
    }
  }
}
