# release

`release` is a Pi skill for finishing a branch as a single-project release.

It helps the agent:
- compare the current branch against `@{upstream}` plus the working tree;
- update `AGENTS.md`, `README.md`, and `docs/` so documentation matches all committed and uncommitted changes since the last push;
- protect already-pushed plan documents under `docs/plans/`;
- choose and apply `npm version patch|minor|major` when `package.json` exists;
- commit all current uncommitted files and push;
- optionally `npm publish` and then `pi install npm:PACKAGE_NAME` after a 30 second wait;
- print `git show --stat` at the end.

## Installation

For local use, symlink the skill into your Pi skills directory:

```bash
ln -s /path/to/my-skills/release ~/.pi/agent/skills/release
```

For one-off runs, you can also point Pi at the directory explicitly:

```bash
pi --no-skills --skill /path/to/my-skills/release
```

## Repository assumptions

- The current directory is inside a git repository.
- The branch has an upstream configured.
- This skill targets one package or project at a time.
- If `package.json` exists, it is at the repository root.

When invoking the bundled scripts manually, stay in the repository you want to release and call the helpers via their absolute path inside the installed skill directory, for example `/absolute/path/to/release/scripts/release_context.py`.

## Protected `docs/plans/` handling

- Already-pushed `docs/plans/*_plan.md` files are never edited.
- Already-pushed `docs/plans/*_design.md` files are not rewritten; instead, the skill updates an `OUTDATED` section near the top.

## Bundled scripts

- `scripts/release_context.py` — summarize upstream, changed files, documentation candidates, protected plan/design files, and package metadata.
- `scripts/mark_outdated_design.py` — insert or refresh an `OUTDATED` section in a pushed design document.
- `scripts/npm_version.sh` — run `npm version patch|minor|major --no-git-tag-version`.
- `scripts/git_release.sh` — stage all files, commit, and push.
- `scripts/npm_publish_and_reinstall.sh` — run `npm publish` when configured and optionally reinstall through Pi.
- `scripts/final_release_summary.sh` — print `git show --stat` for the latest commit.

## Usage

Invoke the skill from Pi when you want the agent to perform the full release flow automatically.

The skill itself is not packaged as an npm module yet; use it as a normal skill directory from this repository.
