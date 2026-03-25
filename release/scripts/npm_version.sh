#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: bash scripts/npm_version.sh <patch|minor|major>

Runs `npm version <bump> --no-git-tag-version` from the current repository root.
EOF
}

if [[ "${1-}" == "--help" || "${1-}" == "-h" ]]; then
  usage
  exit 0
fi

if [[ $# -ne 1 ]]; then
  usage >&2
  exit 1
fi

bump="$1"
case "$bump" in
  patch|minor|major) ;;
  *)
    echo "error: bump must be one of patch, minor, or major" >&2
    exit 1
    ;;
esac

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

if [[ ! -f package.json ]]; then
  echo "error: package.json not found in $repo_root" >&2
  exit 1
fi

npm version "$bump" --no-git-tag-version
node -p 'require("./package.json").version'
