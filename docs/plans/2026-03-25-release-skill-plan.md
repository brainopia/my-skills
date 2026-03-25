# Implement the `release` Pi skill for branch-aware docs sync and automated release steps

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

`execplan/references/PLANS.md` is checked into this repository. This document must be maintained in accordance with `execplan/references/PLANS.md`.

## Purpose / Big Picture

After this change, a Pi user can invoke the new `release` skill in a repository and get a repeatable release workflow that matches the user’s rules. The agent will compare the current branch against its upstream plus the working tree, update project documentation so it reflects all committed and uncommitted changes since the last push, treat already-pushed `docs/plans/` files safely, pick an appropriate semantic-version bump when `package.json` exists, commit every current uncommitted file, push, optionally publish, optionally reinstall through Pi, and finally print `git show --stat` so the user can inspect the release size.

The visible proof of success is straightforward. Reading `release/SKILL.md` and `release/README.md` should show the exact workflow and restrictions. Running the helper scripts with `--help` or in a dry informational mode should show that the mechanical steps are packaged into scripts instead of being left to ad hoc shell commands.

## Progress

- [x] (2026-03-25 17:14 UTC+8) Reviewed repository structure, existing skill conventions, `brainstorming/SKILL.md`, `skill-creator/SKILL.md`, `execplan/references/PLANS.md`, and the Pi documentation for skills and packages.
- [x] (2026-03-25 17:14 UTC+8) Confirmed the product requirements with the user: single-package scope, semver chosen by change analysis instead of Conventional Commits, fully automatic push and publish behavior, inclusion of all current uncommitted files in the release commit, baseline of `@{upstream}..HEAD` plus working tree, and a final `git show --stat` output.
- [x] (2026-03-25 17:17 UTC+8) Created the new `release/` skill directory with `release/SKILL.md`, `release/README.md`, and six helper scripts covering release context discovery, `OUTDATED` updates for pushed design docs, npm versioning, git commit/push, npm publish plus optional Pi reinstall, and the final `git show --stat` summary.
- [x] (2026-03-25 17:18 UTC+8) Validated the new scripts and skill text from the repository root: checked help output for every script, ran `release_context.py` against this repo, verified `mark_outdated_design.py` on a temporary file, fixed an initial README validator complaint by adding an Installation section, re-ran the validator successfully, and recorded the final evidence below.
- [x] (2026-03-25 17:25 UTC+8) Re-verified the implementation with end-to-end temporary-repo tests, found that the original SKILL command examples incorrectly pointed at `scripts/...` inside the target repository, corrected the docs to require absolute paths into the installed skill directory, and re-ran validation successfully.

## Surprises & Discoveries

- Observation: The repository root currently has no `AGENTS.md` or `README.md`, so the new skill cannot assume those files always exist in the repositories where it runs.
  Evidence: `read AGENTS.md` and `read README.md` both failed with “File not found or not readable”.
- Observation: The repository already contains packaged examples under `extending-pi/` and `extending-pi/skill-creator/`, but there is no root-level package manifest that forces the new skill itself to become an npm package right now.
  Evidence: `find . -maxdepth 4 -type f` found `extending-pi/package.json` and `extending-pi/skill-creator/package.json`, but none at the repository root.
- Observation: `npm version patch --no-git-tag-version` succeeds even with unrelated working-tree changes, which fits the user’s request to release and commit everything in one later commit.
  Evidence: A temporary git repo test with a dirty `README.md` exited with code 0 and printed `v1.0.1`.
- Observation: The existing skill validator expects a human-facing `README.md` to include an Installation section when the file exists, even for a local-only skill that is not yet packaged as an npm module.
  Evidence: `python3 extending-pi/skill-creator/scripts/validate_skill.py release` first failed with `README.md is missing an Installation section`; after adding `## Installation` with symlink and `--skill` usage, the same command reported `Skill is valid!`.
- Observation: The first version of `release/SKILL.md` described helper invocations as `scripts/...` commands from the target repository, but the helper files actually live inside the installed skill directory, so those examples would fail in real use.
  Evidence: Running `python3 scripts/release_context.py` from a temporary test repo failed with `can't open file .../repo/scripts/release_context.py`; after changing the docs to `/absolute/path/to/release/scripts/...`, end-to-end temporary-repo tests for context discovery, `OUTDATED` updates, versioning, commit/push, publish/reinstall, and final `git show --stat` all passed.

## Decision Log

- Decision: Implement `release` as a new top-level skill directory rather than nesting it under an existing package.
  Rationale: The task is to create a reusable Pi skill, and top-level placement matches the current repository’s skill-centric structure while avoiding accidental coupling to `extending-pi`.
  Date/Author: 2026-03-25 / OpenAI Codex
- Decision: Keep the first version of the skill single-package only and define the release scope as the current git repository.
  Rationale: The user explicitly selected the simpler single-package mode, and that keeps the scripts safer and more predictable.
  Date/Author: 2026-03-25 / OpenAI Codex
- Decision: Let the agent choose `patch`, `minor`, or `major`, but move all deterministic execution into bundled scripts.
  Rationale: The user asked for semver selection by change analysis, while also asking that easily automated actions move into scripts.
  Date/Author: 2026-03-25 / OpenAI Codex
- Decision: Do not add `release/package.json` in this implementation.
  Rationale: The user did not provide npm package naming or publishing metadata for the skill itself, and omitting the manifest avoids baking in assumptions while still leaving the skill fully usable from a skill directory.
  Date/Author: 2026-03-25 / OpenAI Codex
- Decision: Treat already-pushed `docs/plans/*_design.md` files as append-only for release notes via an `OUTDATED` section instead of rewriting their main body.
  Rationale: The user explicitly asked for this safety rule, and bundling that edit into a helper script makes the rule repeatable and idempotent.
  Date/Author: 2026-03-25 / OpenAI Codex
- Decision: Keep `release/README.md` local-install oriented instead of inventing package-manager metadata for the skill itself.
  Rationale: The implementation intentionally omits `release/package.json`, but the validator still expects installation guidance in the README. Local symlink and `pi --skill` instructions satisfy that requirement without making up npm publishing details.
  Date/Author: 2026-03-25 / OpenAI Codex
- Decision: Document every helper invocation with an absolute path into the installed skill directory while keeping the shell working directory in the repository being released.
  Rationale: Pi skills can reference bundled scripts relative to the skill directory, but shell commands execute in the current working directory. Explicit absolute-path examples remove ambiguity and match the real file layout.
  Date/Author: 2026-03-25 / OpenAI Codex

## Outcomes & Retrospective

Implementation is complete and has now been re-verified against realistic temporary repositories. The repository contains a new top-level `release` skill with machine-facing instructions in `release/SKILL.md`, a human overview in `release/README.md`, and six executable helper scripts under `release/scripts/`. The skill text codifies the user’s requested behavior: single-repository scope, diff baseline of `@{upstream}..HEAD` plus the working tree, documentation synchronization before versioning, protected handling for already-pushed `docs/plans/*_plan.md` and `docs/plans/*_design.md`, agent-selected semver bumps, automatic commit-and-push of all current uncommitted files, optional `npm publish`, optional delayed `pi install`, and a final `git show --stat` output.

The re-verification uncovered one real documentation bug: the original command examples implied that the helper scripts lived under `scripts/` in the target repository. That would not work, because the helpers are bundled inside the installed `release` skill directory. The docs now explicitly require absolute paths such as `/absolute/path/to/release/scripts/release_context.py` while keeping the shell working directory inside the repository being released. After that fix, validation succeeded in three layers: the skill validator passed, focused searches confirmed the corrected absolute-path instructions and the required release rules, and end-to-end temporary-repo tests succeeded for context discovery, protected design updates, version bumping, commit/push, simulated publish plus delayed Pi reinstall, and final `git show --stat`. The main remaining follow-up is still optional future packaging metadata if the user later wants to publish the skill itself as an npm-installable Pi package.

## Context and Orientation

This repository stores Pi skills as directories containing `SKILL.md`, optional `README.md`, and optional helper resources. The relevant examples are `brainstorming/`, `execplan/`, `extending-pi/`, and `extending-pi/skill-creator/`. The new `release/` directory will follow the same broad pattern, but it will include more scripts because the user wants deterministic automation extracted from the skill text.

A Pi skill is a directory that Pi discovers and loads on demand. `release/SKILL.md` is the machine-facing instruction document the agent reads when it decides to use the skill. `release/README.md` is the human-facing overview. The `release/scripts/` directory will contain executable helpers that the agent invokes using absolute paths resolved from the skill directory. In this task, “upstream” means the branch named by `git rev-parse --abbrev-ref @{upstream}`. “Changes since the last push” means two sets combined: commits reachable from `HEAD` but not from `@{upstream}`, and the current staged, unstaged, or untracked working-tree files.

The release workflow itself has several special rules that must appear both in the skill and in the scripts’ behavior. Existing `docs/plans/*_plan.md` files that are already pushed must not be modified. Existing `docs/plans/*_design.md` files that are already pushed must not be rewritten; instead, a short `OUTDATED` section near the top of the file should summarize stale items and, when possible, point to newer design documents. If `package.json` exists, the agent must decide whether the branch is a patch, minor, or major release, then invoke a helper script that runs `npm version --no-git-tag-version`. After documentation and versioning are done, all current uncommitted files must be committed together and pushed. If `package.json` contains `publishConfig`, a publish helper must run `npm publish`; if `pi list` already contains `npm:PACKAGE_NAME`, the helper must wait 30 seconds and then run `pi install npm:PACKAGE_NAME`. The last visible action must be `git show --stat` so the user sees the release volume.

## Plan of Work

Start by creating `release/` and populating it with the minimum human and agent-facing documentation. In `release/SKILL.md`, explain the trigger conditions clearly: use this skill when a repository needs a release that synchronizes docs with branch changes, performs safe semver bumps, and automates the final release mechanics. The body should instruct the agent to first run a bundled context script, then read and update `AGENTS.md`, `README.md`, and the editable files under `docs/` that need to reflect branch changes. It must also explain the protected handling for already-pushed `docs/plans/*_design.md` and `docs/plans/*_plan.md`, the semver rubric, and the exact ordering of versioning, commit/push, optional publish/reinstall, and final summary.

Then create the helper scripts in `release/scripts/`. `release_context.py` should inspect git and package state and print a concise but structured summary the agent can use to decide what to read and edit. `mark_outdated_design.py` should accept a target design file and one or more bullet items, then insert or refresh a dedicated `OUTDATED` section near the top of the file without disturbing the rest of the document. `npm_version.sh` should validate its single bump argument and call `npm version <bump> --no-git-tag-version`. `git_release.sh` should stage everything, choose or accept a commit message, commit if needed, push to the current upstream, and print the new commit identifier. `npm_publish_and_reinstall.sh` should detect `publishConfig`, publish when required, inspect `pi list`, and perform the 30-second delayed reinstall when the package source is already present. `final_release_summary.sh` should simply print `git show --stat` for the newest commit.

After the files exist, validate them in layers. Read the new `SKILL.md` and `README.md` end to end to ensure they express the exact user-approved behavior and do not quietly drift on ordering or protected-file rules. Run the scripts in informational or help mode from `/home/bot/projects/my-skills` to ensure they are executable and print understandable guidance. Run the skill validator script already present at `extending-pi/skill-creator/scripts/validate_skill.py` against `release/`. Finally, record the validation outputs, any implementation surprises, and the completion state in this ExecPlan before stopping.

## Concrete Steps

Work from the repository root `/home/bot/projects/my-skills`.

1. Create the directory `release/` with `release/SKILL.md`, `release/README.md`, and `release/scripts/`.

2. In `release/SKILL.md`, write a concise but explicit release workflow that does all of the following:
   - defines the skill’s purpose and single-package scope,
   - tells the agent to gather context with `release/scripts/release_context.py`,
   - requires documentation updates for `AGENTS.md`, `README.md`, and editable `docs/` files when they need to reflect branch changes,
   - prohibits editing already-pushed `docs/plans/*_plan.md`,
   - routes already-pushed `docs/plans/*_design.md` changes through `release/scripts/mark_outdated_design.py`,
   - explains the `patch` versus `minor` versus `major` rubric,
   - orders the automated steps as version, commit/push, optional publish/reinstall, final `git show --stat`.

3. In `release/README.md`, summarize the workflow for humans and list the scripts with one-line descriptions.

4. Implement the helper scripts under `release/scripts/` exactly as named in the design. Each script must support a clear usage path or `--help` output and must resolve repo state from the current working directory.

5. Make the scripts executable.

6. Run the following validation commands from `/home/bot/projects/my-skills` and compare the output to the expected behaviors.

    python3 release/scripts/release_context.py --help

    Expected result: usage text that explains the context summary and available output mode.

    python3 release/scripts/mark_outdated_design.py --help

    Expected result: usage text that explains how to supply the target file and bullet items.

    bash release/scripts/npm_version.sh --help

    Expected result: a short usage message naming `patch`, `minor`, and `major`.

    bash release/scripts/git_release.sh --help

    Expected result: a short usage message describing staging, commit, and push.

    bash release/scripts/npm_publish_and_reinstall.sh --help

    Expected result: a short usage message describing publish and optional Pi reinstall.

    bash release/scripts/final_release_summary.sh --help

    Expected result: a short usage message noting that the normal behavior prints `git show --stat`.

    python3 extending-pi/skill-creator/scripts/validate_skill.py release

    Expected result: the skill validates successfully, or only emits warnings that do not contradict the Agent Skills rules.

    rg -n "@\{upstream\}|OUTDATED|git show --stat|publishConfig|docs/plans/.+_plan\.md|docs/plans/.+_design\.md" release/SKILL.md release/README.md

    Expected result: matches that prove the new docs describe the baseline, protected plan/design handling, publish rule, and final summary step.

7. Update this ExecPlan’s `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` sections with the actual implementation and validation results before stopping.

## Validation and Acceptance

The work is accepted when the repository contains a new `release/` skill whose instructions match the approved behavior exactly. A novice reading only `release/SKILL.md` must understand that this skill targets one package or repository, compares `HEAD` against `@{upstream}` plus the working tree, updates user-facing documentation to match those changes, does not touch already-pushed `docs/plans/*_plan.md`, uses an `OUTDATED` section for already-pushed `docs/plans/*_design.md`, chooses a semver bump by change analysis, commits all current uncommitted files, pushes, optionally publishes, optionally reinstalls through Pi, and ends by printing `git show --stat`.

The scripts must also prove that the easily automated steps are actually automated. Help output must exist for each script, the skill validator must accept `release/`, and the new docs must visibly mention the special rules and ordering. Because this task adds a skill rather than application runtime code, validation is based on discoverability, script usability, and documentation fidelity rather than on a separate unit-test suite.

## Idempotence and Recovery

These changes are safe to repeat because they add a new skill directory and repository-local documentation. Re-running the directory creation step should leave existing files in place and only require targeted edits. The helper scripts themselves should be written defensively: usage output on bad arguments, clear failures when no git upstream exists, and no destructive behavior outside the current repository. If a script lands with incorrect wording or behavior, re-read the file, replace only the affected section, and re-run the relevant help or validation command until the expected output matches. If validation reveals unrelated diffs, inspect `git diff -- release docs/plans/2026-03-25-release-skill-design.md docs/plans/2026-03-25-release-skill-plan.md` and revert only the unintended lines before continuing.

## Artifacts and Notes

The implementation should leave behind the following concrete artifacts in the repository:

    release/SKILL.md
    release/README.md
    release/scripts/release_context.py
    release/scripts/mark_outdated_design.py
    release/scripts/npm_version.sh
    release/scripts/git_release.sh
    release/scripts/npm_publish_and_reinstall.sh
    release/scripts/final_release_summary.sh

The skill’s essential runtime contract is summarized here so future contributors can validate drift quickly.

    1. Read branch state relative to @{upstream} and the working tree.
    2. Update AGENTS.md, README.md, and docs/ where needed.
    3. Never edit already-pushed *_plan.md files.
    4. Use an OUTDATED section for already-pushed *_design.md files.
    5. If package.json exists, choose patch/minor/major and run npm version.
    6. Commit every current uncommitted file and push.
    7. If publishConfig exists, run npm publish.
    8. If pi list contains npm:PACKAGE_NAME, wait 30 seconds and reinstall.
    9. Finish with git show --stat.

## Interfaces and Dependencies

The implementation depends on git, npm, python3, and the existing Pi CLI being available in the environment where the skill runs. The scripts should assume they are executed from somewhere inside the target repository and should derive the repository root with git commands rather than with hard-coded paths.

In `release/scripts/release_context.py`, expose a command-line interface that supports human-readable output by default and JSON output via `--json`. The output must include repository root, branch, upstream, committed files since upstream, working-tree files, documentation candidates, protected pushed design files, protected pushed plan files, and package metadata when `package.json` exists.

In `release/scripts/mark_outdated_design.py`, expose a command-line interface that requires a target markdown file plus one or more bullet items. The script must insert an `## OUTDATED` section near the top of the file, replacing an existing generated `OUTDATED` section when present.

In `release/scripts/npm_version.sh`, implement the interface `npm_version.sh <patch|minor|major>`. In `release/scripts/git_release.sh`, support `git_release.sh [commit-message]` and auto-generate a reasonable release message when no explicit message is supplied. In `release/scripts/npm_publish_and_reinstall.sh`, support no arguments when `package.json` is present in the current repo, but also permit `--package-name <name>` for recovery or testing. In `release/scripts/final_release_summary.sh`, support no arguments and print `git show --stat`; `--help` should explain that behavior.

Revision note: 2026-03-25 implementation completed and then re-verified; corrected the SKILL and README command examples to use absolute paths into the installed skill directory, re-ran validator checks, exercised the helpers against temporary git repositories, and recorded the discovered pathing bug plus its fix.