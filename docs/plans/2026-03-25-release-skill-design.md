# Create a `release` skill for documentation sync, versioning, publishing, and push

## Summary

This design adds a new top-level Pi skill named `release`. The skill is meant for a single package or repository rooted at the current working directory. When invoked, it helps the agent update project documentation so it matches all committed and uncommitted changes since the last push, applies special handling to already-pushed design and plan documents under `docs/plans/`, bumps `package.json` with `npm version patch|minor|major` based on the agent’s analysis, commits all current uncommitted files, pushes the branch, optionally publishes the package, optionally reinstalls it through Pi, and finishes by printing `git show --stat`.

The skill keeps judgment-heavy work in the model and pushes deterministic work into bundled scripts. In practice, the agent will use scripts to collect release context, update `OUTDATED` sections in protected design documents, run `npm version`, commit and push, publish, perform the optional Pi reinstall, and show the final release summary.

## Scope

- Add a new top-level skill directory at `release/`.
- Add `release/SKILL.md` with the workflow, guardrails, and semver decision rubric.
- Add `release/README.md` for humans.
- Add bundled helper scripts under `release/scripts/` for deterministic git/npm/doc operations.
- Add design and plan documents under `docs/plans/` for this work.
- Do not modify unrelated existing skills.

## Key decisions

### Single-package scope

The skill will target one releaseable package or repository at a time: the current working directory and its git repo. It will not attempt workspace or multi-package orchestration.

### Diff baseline

The skill will define “changes since the last push” as `@{upstream}..HEAD` plus the current working tree, including staged, unstaged, and untracked files.

### Protected plan files

Already-pushed `docs/plans/*_plan.md` files are never edited. Already-pushed `docs/plans/*_design.md` files are not rewritten; instead, the agent will summarize stale points and then call a helper script that inserts or refreshes an `OUTDATED` section near the top of the document.

### Version bump ownership

The agent, not the scripts, decides whether the release is `patch`, `minor`, or `major`. The scripts only execute the chosen bump safely with `npm version --no-git-tag-version`.

### Automation split

The helper scripts will cover the repeatable parts:

- release context discovery,
- `OUTDATED` section updates,
- version bump execution,
- commit and push,
- publish plus optional Pi reinstall,
- final `git show --stat` output.

The agent remains responsible for reading relevant docs and editing them so they accurately reflect the code and behavior changes in the branch.

### Packaging of the skill itself

This initial implementation will not add a `release/package.json`. That avoids inventing npm metadata or package ownership details that the user did not specify. The skill remains usable as a normal Pi skill directory and can be packaged later if needed.

## File changes

### `release/SKILL.md`

Describe when to use the skill, how to gather release context, how to choose documentation files to edit, how to treat protected `docs/plans/` files, how to choose semver, and in what order to run the scripts. Make the final step explicitly print `git show --stat`.

### `release/README.md`

Provide a human-readable summary of the workflow, the repository assumptions, and the bundled scripts.

### `release/scripts/release_context.py`

Collect git and package metadata for the current repo: repo root, current branch, upstream branch, committed range since upstream, working-tree changes, documentation candidates, protected plan/design files, package name, and whether `publishConfig` exists.

### `release/scripts/mark_outdated_design.py`

Insert or replace an `OUTDATED` section in a specific design document, ideally immediately after the title when one exists, using agent-supplied bullet items.

### `release/scripts/npm_version.sh`

Run `npm version patch|minor|major --no-git-tag-version` from the repo root.

### `release/scripts/git_release.sh`

Stage all files with `git add -A`, create a release commit with either an agent-supplied or auto-generated message, push to the current upstream, and print the resulting commit SHA.

### `release/scripts/npm_publish_and_reinstall.sh`

If `publishConfig` exists, run `npm publish`. Then inspect `pi list`; if `npm:PACKAGE_NAME` is already installed, wait 30 seconds and run `pi install npm:PACKAGE_NAME`.

### `release/scripts/final_release_summary.sh`

Print `git show --stat` for the newest commit so the user can review release volume after the fact.

## Acceptance

- The repository contains a new `release/` skill with `SKILL.md`, `README.md`, and helper scripts.
- The skill text clearly states the single-package scope and the `@{upstream}..HEAD` plus working-tree baseline.
- The skill forbids editing already-pushed `docs/plans/*_plan.md` files and routes already-pushed `docs/plans/*_design.md` changes through the `OUTDATED` helper script.
- The version step uses agent judgment for `patch|minor|major` and a helper script to run `npm version --no-git-tag-version`.
- The git, publish, optional reinstall, and final `git show --stat` steps are automated by bundled scripts.
- Validation shows the new skill is discoverable and the helper scripts expose clear usage or help output.