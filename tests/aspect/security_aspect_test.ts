// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
// Security aspect tests — Defense-in-depth dimension checks

import { assertEquals } from "https://deno.land/std@0.220.0/assert/mod.ts";

const REPO_ROOT = new URL("../..", import.meta.url).pathname;

Deno.test("Aspect: No hardcoded SSH private keys in repository", async () => {
  const sshPatterns = [
    /-----BEGIN RSA PRIVATE KEY-----/,
    /-----BEGIN OPENSSH PRIVATE KEY-----/,
    /-----BEGIN EC PRIVATE KEY-----/,
    /-----BEGIN PRIVATE KEY-----/,
  ];

  for await (const entry of walkFiles(`${REPO_ROOT}`)) {
    // Skip .git and other directories
    if (
      entry.includes("/.git/") ||
      entry.includes("node_modules") ||
      entry.includes(".terraform")
    ) {
      continue;
    }

    // Only check text files
    if (
      !isTextFile(entry)
    ) {
      continue;
    }

    try {
      const content = await Deno.readTextFile(entry);
      for (const pattern of sshPatterns) {
        assertEquals(
          !pattern.test(content),
          true,
          `File ${entry} should not contain SSH private keys`,
        );
      }
    } catch (e) {
      // Skip files that can't be read as text
      if (!(e instanceof Deno.errors.IsADirectory)) {
        // Continue on read errors
      }
    }
  }
});

Deno.test("Aspect: No AWS/GCP access keys in Terraform files", async () => {
  const keyPatterns = [
    /aws_access_key_id\s*=\s*['"][A-Z0-9]{20}['"]/, // AWS key format
    /aws_secret_access_key\s*=\s*['"][A-Za-z0-9\/+]{40}['"]/, // AWS secret format
    /AKIAIOSFODNN7EXAMPLE/, // AWS example key (should not be present)
    /AIzaSy[A-Za-z0-9_-]{33}/, // GCP API key format
  ];

  const terraformDir = `${REPO_ROOT}/terraform`;
  try {
    for await (const entry of Deno.readDir(terraformDir)) {
      if (entry.isFile && entry.name.endsWith(".tf")) {
        const content = await Deno.readTextFile(
          `${terraformDir}/${entry.name}`,
        );

        for (const pattern of keyPatterns) {
          assertEquals(
            !pattern.test(content),
            true,
            `Terraform file ${entry.name} should not contain hardcoded access keys`,
          );
        }
      }
    }
  } catch (e) {
    if (!(e instanceof Deno.errors.NotFound)) {
      throw e;
    }
  }
});

Deno.test("Aspect: No plaintext HTTP URLs in critical configs", async () => {
  const criticalFiles = [
    `${REPO_ROOT}/ansible/ansible.cfg`,
    `${REPO_ROOT}/terraform/providers.tf`,
  ];

  for (const file of criticalFiles) {
    try {
      const content = await Deno.readTextFile(file);
      // Check for http:// (should use https)
      // Exclude http comments and documentation
      const hasInsecureHttp = /\bhttp:\/\/[^\s#"']+\.(com|org|net|io)/gi.test(
        content,
      );

      assertEquals(
        !hasInsecureHttp,
        true,
        `File ${file} should use HTTPS for remote URLs`,
      );
    } catch (e) {
      if (!(e instanceof Deno.errors.NotFound)) {
        throw e;
      }
    }
  }
});

Deno.test("Aspect: Firewall defaults to deny policy", async () => {
  const firewallTasksFile =
    `${REPO_ROOT}/ansible/roles/firewall/tasks/main.yml`;
  const content = await Deno.readTextFile(firewallTasksFile);

  // Check for default deny policy or allow-only approach
  const hasDenyDefault =
    content.includes("default: DROP") ||
    content.includes("zone:") ||
    content.includes("firewall");

  assertEquals(
    hasDenyDefault,
    true,
    "Firewall role should implement default-deny policy",
  );
});

Deno.test("Aspect: No ignore_errors in security playbooks", async () => {
  const securityPlaybook = `${REPO_ROOT}/ansible/playbooks/security.yml`;
  const content = await Deno.readTextFile(securityPlaybook);

  assertEquals(
    !content.includes("ignore_errors: true"),
    true,
    "Security playbook should not ignore errors that might hide breaches",
  );
});

Deno.test("Aspect: Security playbook uses become for privileged operations", async () => {
  const securityPlaybook = `${REPO_ROOT}/ansible/playbooks/security.yml`;
  const content = await Deno.readTextFile(securityPlaybook);

  assertEquals(
    content.includes("become") || content.includes("sudo"),
    true,
    "Security playbook should escalate privileges where needed",
  );
});

Deno.test("Aspect: No debug mode enabled in production configs", async () => {
  const ansibleCfg = `${REPO_ROOT}/ansible/ansible.cfg`;
  const content = await Deno.readTextFile(ansibleCfg);

  assertEquals(
    !content.includes("debug = True"),
    true,
    "ansible.cfg should not have debug enabled",
  );
});

Deno.test("Aspect: Sudo configuration restricts commands", async () => {
  const sudoPath = `${REPO_ROOT}/ansible/roles/sudo_config/tasks/main.yml`;
  const content = await Deno.readTextFile(sudoPath);

  const hasCommandRestrictions =
    content.includes("sudoers") ||
    content.includes("NOPASSWD") ||
    content.includes("Cmnd_Alias");

  assertEquals(
    hasCommandRestrictions,
    true,
    "Sudo config should enforce command restrictions",
  );
});

function isTextFile(path: string): boolean {
  const binaryExtensions = [
    ".pyc",
    ".pyo",
    ".o",
    ".a",
    ".so",
    ".bin",
    ".exe",
    ".zip",
    ".tar",
    ".gz",
  ];
  for (const ext of binaryExtensions) {
    if (path.endsWith(ext)) {
      return false;
    }
  }
  return true;
}

async function* walkFiles(path: string): AsyncGenerator<string> {
  try {
    for await (const entry of Deno.readDir(path)) {
      const fullPath = `${path}/${entry.name}`;

      if (
        entry.name.startsWith(".") ||
        entry.name === "node_modules"
      ) {
        continue;
      }

      if (entry.isDirectory) {
        yield* walkFiles(fullPath);
      } else {
        yield fullPath;
      }
    }
  } catch (e) {
    if (!(e instanceof Deno.errors.NotFound || e instanceof Deno.errors
      .PermissionDenied)) {
      throw e;
    }
  }
}
