---
name: release
description: Synchronize AGENTS.md, README.md, and docs with all committed and uncommitted changes since the last push, then bump npm version, commit every file, push, optionally publish, and optionally reinstall via pi. Use when releasing the current repository as a single package or project.
---

# Release

Use this skill when the current repository is ready for a release and you need a disciplined final pass over documentation plus the mechanical release steps.

This skill is intentionally opinionated:
- treat the current git repository as the only release target;
- define “changes since the last push” as `@{upstream}..HEAD` plus the current working tree;
- update documentation before versioning or publishing;
- commit **all** current uncommitted files;
- push automatically once the release changes are ready;
- if publishing is configured, publish automatically;
- finish by printing `git show --stat`.

All script paths below refer to files inside this skill directory, not files inside the repository being released. Keep your shell working directory in the target repository, but invoke each helper via the skill’s absolute path, for example `/absolute/path/to/release/scripts/release_context.py`.

## Before you start

1. Resolve the target repository root from the current working directory.
2. Run `/absolute/path/to/release/scripts/release_context.py` while your shell is still in the target repository.
3. If the context script reports that no upstream branch is configured, stop and tell the user. This skill relies on `@{upstream}`.
4. Read the relevant source changes, not just documentation files. The documentation must match both committed and uncommitted branch changes.

## Documentation rules

Always check these locations when they exist:
- `AGENTS.md`
- `README.md`
- files under `docs/`

Use the context script output to identify protected plan files.

### `docs/plans/*_plan.md`

If a plan file has already been pushed to the upstream branch, do not edit it.

If a plan file is new and not yet pushed, you may edit it when it is part of the current release work.

### `docs/plans/*_design.md`

If a design file has already been pushed, do not rewrite the main body. Instead, summarize the stale points and update an `OUTDATED` section near the top by calling:

```bash
/absolute/path/to/release/scripts/mark_outdated_design.py docs/plans/2026-03-25-example_design.md \
  --item "Old behavior X is no longer correct; see docs/plans/2026-03-26-example_design.md" \
  --item "Command Y was renamed to Z"
```

Prefer bullets that say exactly what is stale and, when possible, point to the newer design document that supersedes it.

If a design file is new and not yet pushed, you may edit it normally.

## Choosing the version bump

If `package.json` exists in the repository root, you must choose `patch`, `minor`, or `major` by analyzing the actual branch changes.

Use this rubric:
- **major**: a breaking change to a published interface, installation flow, compatibility promise, or documented usage pattern;
- **minor**: a new user-facing capability, command, supported workflow, or documented feature that remains backward compatible;
- **patch**: fixes, doc corrections, internal refactors, packaging tweaks, maintenance, or other backward-compatible changes that do not expand the public surface in a meaningful way.

If the change set mixes categories, pick the highest applicable bump.

Then run:

```bash
bash /absolute/path/to/release/scripts/npm_version.sh <patch|minor|major>
```

The helper uses `npm version --no-git-tag-version` so the version change becomes part of the final release commit instead of creating its own git commit or tag.

## Release order

Follow this exact sequence.

### 1. Gather release context

Run:

```bash
/absolute/path/to/release/scripts/release_context.py
```

Use the result to identify:
- the upstream branch;
- committed files in `@{upstream}..HEAD`;
- current staged, unstaged, and untracked files;
- documentation candidates;
- pushed `*_design.md` files that need `OUTDATED` handling;
- pushed `*_plan.md` files that must remain untouched;
- package metadata and whether `publishConfig` exists.

### 2. Update documentation

Read the affected code, diffs, and existing docs. Then update the documentation files that need to reflect the branch state.

Do not create fictional documentation. If `AGENTS.md` or `README.md` does not exist, skip it unless the release work itself explicitly introduced that file.

### 3. Apply the version bump when `package.json` exists

After the docs are correct, run `bash /absolute/path/to/release/scripts/npm_version.sh <patch|minor|major>`.

### 4. Commit every current uncommitted file and push

Run:

```bash
bash /absolute/path/to/release/scripts/git_release.sh
```

You may pass a commit message explicitly if the auto-generated release message would be misleading:

```bash
bash /absolute/path/to/release/scripts/git_release.sh "release: my-package v1.2.3"
```

This script stages everything with `git add -A`, commits if there are new working-tree changes, and pushes to the current upstream.

### 5. Publish and optionally reinstall

If `package.json` exists, run:

```bash
bash /absolute/path/to/release/scripts/npm_publish_and_reinstall.sh
```

The helper will:
- skip cleanly when `publishConfig` is absent;
- run `npm publish` when `publishConfig` exists;
- inspect `pi list` for `npm:PACKAGE_NAME`;
- wait 30 seconds and run `pi install npm:PACKAGE_NAME` when that package is already installed in Pi.

### 6. Print the final release summary

Always finish with:

```bash
bash /absolute/path/to/release/scripts/final_release_summary.sh
```

That helper prints `git show --stat` so the user can review the release volume after the fact.

## Notes on behavior

- Do not stop for confirmation before `git push`, `npm publish`, or `pi install`. Invoking this skill is the confirmation.
- Do not try to be selective about uncommitted files. The user explicitly wants all current uncommitted files included in the release commit.
- If there is no `package.json`, skip the version and publish steps, but still update docs, commit all files, push, and print `git show --stat`.
- If the repo has no upstream, fail fast with a clear explanation instead of guessing a diff base.
