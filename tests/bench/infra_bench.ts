// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
// Benchmarks — Infrastructure configuration performance baseline

const REPO_ROOT = new URL("../..", import.meta.url).pathname;

Deno.bench(
  "bench: read all ansible playbooks",
  async () => {
    const files = [
      "site.yml",
      "base.yml",
      "security.yml",
      "monitoring.yml",
      "containers.yml",
      "development.yml",
    ];
    await Promise.all(
      files.map((f) =>
        Deno.readTextFile(`${REPO_ROOT}/ansible/playbooks/${f}`)
      ),
    );
  },
);

Deno.bench(
  "bench: enumerate all role directories",
  async () => {
    const entries = [];
    for await (const e of Deno.readDir(`${REPO_ROOT}/ansible/roles`)) {
      entries.push(e);
    }
  },
);

Deno.bench(
  "bench: read inventory hosts.yml",
  async () => {
    await Deno.readTextFile(`${REPO_ROOT}/ansible/inventory/hosts.yml`);
  },
);

Deno.bench(
  "bench: enumerate group_vars",
  async () => {
    const entries = [];
    for await (const e of Deno.readDir(
      `${REPO_ROOT}/ansible/inventory/group_vars`,
    )) {
      entries.push(e);
    }
  },
);

Deno.bench(
  "bench: read all terraform main files",
  async () => {
    const files = ["main.tf", "variables.tf", "outputs.tf", "versions.tf"];
    const promises = files.map((f) => {
      const path = `${REPO_ROOT}/terraform/${f}`;
      return Deno.readTextFile(path).catch(() => null);
    });
    await Promise.all(promises);
  },
);

Deno.bench(
  "bench: enumerate terraform modules",
  async () => {
    const entries = [];
    try {
      for await (const e of Deno.readDir(`${REPO_ROOT}/terraform/modules`)) {
        entries.push(e);
      }
    } catch (e) {
      if (!(e instanceof Deno.errors.NotFound)) {
        throw e;
      }
    }
  },
);

Deno.bench(
  "bench: read ansible.cfg",
  async () => {
    await Deno.readTextFile(`${REPO_ROOT}/ansible/ansible.cfg`);
  },
);

Deno.bench(
  "bench: enumerate all scripts",
  async () => {
    const entries = [];
    for await (const e of Deno.readDir(`${REPO_ROOT}/scripts`)) {
      entries.push(e);
    }
  },
);
