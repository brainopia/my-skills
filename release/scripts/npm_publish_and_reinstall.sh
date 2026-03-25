#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: bash scripts/npm_publish_and_reinstall.sh [--package-name <name>]

If package.json contains publishConfig, run `npm publish`. Then inspect `pi list`;
if `npm:PACKAGE_NAME` is already installed, wait 30 seconds and run
`pi install npm:PACKAGE_NAME`.
EOF
}

if [[ "${1-}" == "--help" || "${1-}" == "-h" ]]; then
  usage
  exit 0
fi

package_name_override=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --package-name)
      if [[ $# -lt 2 ]]; then
        echo "error: --package-name requires a value" >&2
        exit 1
      fi
      package_name_override="$2"
      shift 2
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

if [[ ! -f package.json ]]; then
  echo "No package.json found; skipping publish and reinstall steps."
  exit 0
fi

package_name="$package_name_override"
if [[ -z "$package_name" ]]; then
  package_name="$(node -p 'require("./package.json").name || ""')"
fi

if [[ -z "$package_name" ]]; then
  echo "error: could not determine package name" >&2
  exit 1
fi

if ! node <<'EOF'
const pkg = require('./package.json');
process.exit(pkg.publishConfig ? 0 : 1);
EOF
then
  echo "publishConfig is absent; skipping npm publish and pi reinstall."
  exit 0
fi

npm publish

source_spec="npm:${package_name}"
if pi list | awk -v target="$source_spec" '$1 == target { found=1 } END { exit found ? 0 : 1 }'; then
  echo "Found $source_spec in pi list; waiting 30 seconds before reinstalling."
  sleep 30
  pi install "$source_spec"
else
  echo "$source_spec is not currently installed in pi; skipping pi install."
fi
