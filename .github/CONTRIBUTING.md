# Contributing

## Development Workflow

1.  Read `0-AI-MANIFEST.a2ml` for project conventions

2.  Read `.machine_readable/STATE.scm` for current status

3.  Make changes following existing patterns

4.  Test with `just` `check` (dry run)

5.  Validate with `just` `lint`

6.  Run `just` `self-check` to verify

## Role Development

When adding a new Ansible role:

1.  Create directory structure: `tasks/`, `defaults/`, `meta/`

2.  Add `meta/main.yml` with role metadata (homoiconic self-description)

3.  Add `defaults/main.yml` with documented default variables

4.  Ensure all tasks are idempotent

5.  Add the role to the appropriate playbook

6.  Update `TOPOLOGY.md`

## Code Standards

- All files must have `#` `SPDX-License-Identifier:` `CC-BY-SA-4.0`

- Ansible tasks must have descriptive `name` fields

- Variables must be documented with comments in `defaults/main.yml`

- Use `ansible.builtin.*` fully qualified collection names

## Signed commits

Every commit that reaches the default branch must be signed; a ruleset refuses
unsigned pushes. Estate policy:
[SIGNING-POLICY](https://github.com/hyperpolymath/standards/blob/main/docs/SIGNING-POLICY.adoc).

- **People and interactive agents** sign with an SSH key registered on GitHub
  as a *signing* key (`gpg.format=ssh`, `user.signingkey=<key>.pub`,
  `commit.gpgsign=true`). The committer email must be verified on that account.
- **Apps, bots and workflows** never `git push` local commits. They write
  through the API (`createCommitOnBranch` or the estate `signed-push` action)
  so that GitHub signs each commit.
- Merge PRs with **squash**. The ruleset checks every commit on the PR branch,
  not just the result, so one unsigned commit blocks the merge. Re-create such a
  branch with signed commits (`git cherry-pick -S`) and open a new PR.
  Rebase-merge replays commits unsigned and is disabled.
