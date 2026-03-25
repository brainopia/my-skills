#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: bash scripts/git_release.sh [commit message]

Stages all files with `git add -A`, commits when there are new working-tree changes,
and pushes to the current upstream branch.
EOF
}

if [[ "${1-}" == "--help" || "${1-}" == "-h" ]]; then
  usage
  exit 0
fi

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

commit_message="${*:-}"
if [[ -z "$commit_message" ]]; then
  if [[ -f package.json ]]; then
    commit_message="$(node <<'EOF'
const pkg = require('./package.json');
const name = pkg.name || 'package';
const version = pkg.version || 'unknown';
process.stdout.write(`release: ${name} v${version}`);
EOF
)"
  else
    commit_message="release: sync documentation and branch changes"
  fi
fi

git add -A

if git diff --cached --quiet --ignore-submodules --exit-code; then
  echo "No new working-tree changes to commit."
else
  git commit -m "$commit_message"
fi

git push

echo "Pushed commit $(git rev-parse HEAD)"
