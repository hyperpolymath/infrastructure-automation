<!-- SPDX-License-Identifier: PMPL-1.0-or-later -->
# Contributing

## Development Workflow

1. Read `0-AI-MANIFEST.a2ml` for project conventions
2. Read `.machine_readable/STATE.scm` for current status
3. Make changes following existing patterns
4. Test with `just check` (dry run)
5. Validate with `just lint`
6. Run `just self-check` to verify

## Role Development

When adding a new Ansible role:

1. Create directory structure: `tasks/`, `defaults/`, `meta/`
2. Add `meta/main.yml` with role metadata (homoiconic self-description)
3. Add `defaults/main.yml` with documented default variables
4. Ensure all tasks are idempotent
5. Add the role to the appropriate playbook
6. Update `TOPOLOGY.md`

## Code Standards

- All files must have `# SPDX-License-Identifier: PMPL-1.0-or-later`
- Ansible tasks must have descriptive `name` fields
- Variables must be documented with comments in `defaults/main.yml`
- Use `ansible.builtin.*` fully qualified collection names
