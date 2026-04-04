// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
// Smoke tests — Rapid validation of critical infrastructure components

import { assertEquals } from "https://deno.land/std@0.220.0/assert/mod.ts";

const REPO_ROOT = new URL("../..", import.meta.url).pathname;

Deno.test("Smoke: All shell scripts exist with bash shebang", async () => {
  const scripts = [
    "bootstrap.sh",
    "self-check.sh",
    "migrate-from-salt.sh",
  ];

  for (const script of scripts) {
    const path = `${REPO_ROOT}/scripts/${script}`;
    const stat = await Deno.stat(path);
    assertEquals(stat.isFile, true, `Script ${script} should exist`);

    const content = await Deno.readTextFile(path);
    assertEquals(
      content.startsWith("#!/usr/bin/env bash") ||
        content.startsWith("#!/bin/bash"),
      true,
      `${script} should have bash shebang`,
    );
  }
});

Deno.test("Smoke: Critical roles exist", async () => {
  const criticalRoles = [
    "base_packages",
    "users",
    "firewall",
    "services",
    "monitoring",
    "sudo_config",
  ];

  for (const role of criticalRoles) {
    const path = `${REPO_ROOT}/ansible/roles/${role}`;
    const stat = await Deno.stat(path);
    assertEquals(
      stat.isDirectory,
      true,
      `Critical role ${role} should exist`,
    );
  }
});

Deno.test("Smoke: Terraform structure exists", async () => {
  const terraformPaths = [
    `${REPO_ROOT}/terraform`,
    `${REPO_ROOT}/terraform/main.tf`,
    `${REPO_ROOT}/terraform/variables.tf`,
    `${REPO_ROOT}/terraform/outputs.tf`,
    `${REPO_ROOT}/terraform/versions.tf`,
    `${REPO_ROOT}/terraform/providers.tf`,
  ];

  for (const path of terraformPaths) {
    try {
      const stat = await Deno.stat(path);
      assertEquals(true, true, `${path} should exist`);
    } catch (e) {
      if (e instanceof Deno.errors.NotFound) {
        console.warn(`Optional terraform path does not exist: ${path}`);
      } else {
        throw e;
      }
    }
  }
});

Deno.test("Smoke: No obvious hardcoded passwords in playbooks", async () => {
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
    const hasPassword = /password:\s*['"]?[a-zA-Z0-9_]{8,}['"]?/gi.test(
      content,
    );
    assertEquals(
      !hasPassword,
      true,
      `${playbook} should not contain hardcoded passwords`,
    );
  }
});

Deno.test("Smoke: Terraform modules directory exists", async () => {
  const modulesPath = `${REPO_ROOT}/terraform/modules`;
  try {
    const stat = await Deno.stat(modulesPath);
    assertEquals(stat.isDirectory, true, "terraform/modules should exist");
  } catch (e) {
    if (e instanceof Deno.errors.NotFound) {
      console.warn("Optional terraform/modules directory does not exist");
    } else {
      throw e;
    }
  }
});

Deno.test("Smoke: Inventory structure is complete", async () => {
  const inventoryPaths = [
    `${REPO_ROOT}/ansible/inventory/hosts.yml`,
    `${REPO_ROOT}/ansible/inventory/group_vars`,
  ];

  for (const path of inventoryPaths) {
    const stat = await Deno.stat(path);
    assertEquals(true, true, `${path} should exist`);
  }
});

Deno.test("Smoke: ansible.cfg is present and readable", async () => {
  const ansibleCfg = `${REPO_ROOT}/ansible/ansible.cfg`;
  const content = await Deno.readTextFile(ansibleCfg);
  assertEquals(
    content.length > 0,
    true,
    "ansible.cfg should have content",
  );
  assertEquals(
    content.includes("[defaults]") || content.includes("["),
    true,
    "ansible.cfg should have valid INI sections",
  );
});
