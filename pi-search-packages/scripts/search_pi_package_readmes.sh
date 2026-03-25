#!/usr/bin/env bash
set -euo pipefail

INDEX_NAME="${PI_SEARCH_PACKAGES_QMD_INDEX:-pi-search-packages}"
COLLECTION_NAME="${PI_SEARCH_PACKAGES_QMD_COLLECTION:-pi-package-readmes}"
LIMIT=10
MIN_SCORE=''
FORMAT='json'
FORCE_REFRESH=0

usage() {
  cat <<'EOF'
Usage: search_pi_package_readmes.sh [options] <query>

Options:
  --refresh             Force a README refresh before searching
  -n, --limit <num>     Maximum number of results (default: 10)
  --min-score <num>     Minimum QMD score filter
  --format <value>      One of: text, json, files, md, csv, xml (default: json)
  -h, --help            Show this help text

This wrapper uses `qmd query`, so the first hybrid search may download local
models and take longer than plain BM25 search.
EOF
}

while (($# > 0)); do
  case "$1" in
    --refresh|--force-refresh)
      FORCE_REFRESH=1
      shift
      ;;
    -n|--limit)
      LIMIT="$2"
      shift 2
      ;;
    --min-score)
      MIN_SCORE="$2"
      shift 2
      ;;
    --format)
      FORMAT="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*)
      printf 'Unknown option: %s\n' "$1" >&2
      usage >&2
      exit 1
      ;;
    *)
      break
      ;;
  esac
done

if (($# == 0)); then
  printf 'Missing query.\n' >&2
  usage >&2
  exit 1
fi

QUERY="$*"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
QMD_RUNNER="$SCRIPT_DIR/run_pi_package_qmd.sh"
MODEL_RUNNER="$SCRIPT_DIR/ensure_pi_package_qmd_models.sh"
ENSURE_ARGS=()
QMD=("$QMD_RUNNER" query "$QUERY" -c "$COLLECTION_NAME" -n "$LIMIT")

if (( FORCE_REFRESH )); then
  ENSURE_ARGS+=(--refresh)
fi

if [[ -n "$MIN_SCORE" ]]; then
  QMD+=(--min-score "$MIN_SCORE")
fi

case "$FORMAT" in
  text)
    ;;
  json)
    QMD+=(--json)
    ;;
  files)
    QMD+=(--files)
    ;;
  md)
    QMD+=(--md)
    ;;
  csv)
    QMD+=(--csv)
    ;;
  xml)
    QMD+=(--xml)
    ;;
  *)
    printf 'Unsupported format: %s\n' "$FORMAT" >&2
    usage >&2
    exit 1
    ;;
esac

"$SCRIPT_DIR/ensure_pi_package_readmes_index.sh" "${ENSURE_ARGS[@]}"
"$MODEL_RUNNER" --mode query
exec "${QMD[@]}"