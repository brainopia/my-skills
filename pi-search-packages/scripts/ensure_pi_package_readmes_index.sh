#!/usr/bin/env bash
set -euo pipefail

CACHE_DIR="${PI_SEARCH_PACKAGES_CACHE_DIR:-$HOME/.pi/cache/pi-search-packages}"
README_DIR="${PI_SEARCH_PACKAGES_READMES_DIR:-$CACHE_DIR/readmes}"
STATE_FILE="${PI_SEARCH_PACKAGES_STATE_FILE:-$CACHE_DIR/last-indexed-at}"
EMBED_STATE_FILE="${PI_SEARCH_PACKAGES_EMBED_STATE_FILE:-$CACHE_DIR/last-embedded-at}"
INDEX_NAME="${PI_SEARCH_PACKAGES_QMD_INDEX:-pi-search-packages}"
COLLECTION_NAME="${PI_SEARCH_PACKAGES_QMD_COLLECTION:-pi-package-readmes}"
FRESHNESS_SECONDS="${PI_SEARCH_PACKAGES_FRESHNESS_SECONDS:-604800}"
FORCE_REFRESH=0

usage() {
  cat <<'EOF'
Usage: ensure_pi_package_readmes_index.sh [--refresh]

Ensures the Pi package README cache exists and the QMD index is current.
Refresh runs automatically on first use, when the cache is older than 7 days,
or when --refresh is provided.

Because search uses `qmd query`, this script also maintains QMD embeddings.
EOF
}

while (($# > 0)); do
  case "$1" in
    --refresh|--force-refresh)
      FORCE_REFRESH=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
QMD_RUNNER="$SCRIPT_DIR/run_pi_package_qmd.sh"
MODEL_RUNNER="$SCRIPT_DIR/ensure_pi_package_qmd_models.sh"

mkdir -p "$README_DIR"

log() {
  printf '%s\n' "$*" >&2
}

write_timestamp() {
  printf '%s\n' "$(date +%s)" > "$1"
}

get_index_db_path() {
  local cache_root
  cache_root="${XDG_CACHE_HOME:-$HOME/.cache}"
  printf '%s\n' "$cache_root/qmd/${INDEX_NAME}.sqlite"
}

get_pending_embedding_count() {
  local db_path
  db_path="$(get_index_db_path)"

  if [[ ! -f "$db_path" ]]; then
    printf '0\n'
    return
  fi

  python3 - "$db_path" <<'PY'
import sqlite3
import sys

db_path = sys.argv[1]
conn = sqlite3.connect(db_path)
cur = conn.cursor()
pending = cur.execute("""
SELECT COUNT(*)
FROM (
  SELECT d.hash
  FROM documents d
  LEFT JOIN content_vectors v ON d.hash = v.hash AND v.seq = 0
  WHERE d.active = 1 AND v.hash IS NULL
  GROUP BY d.hash
) pending_docs
""").fetchone()[0]
print(pending)
PY
}

collection_exists() {
  "$QMD_RUNNER" collection show "$COLLECTION_NAME" >/dev/null 2>&1
}

collection_points_to_readmes() {
  local show_output
  show_output="$("$QMD_RUNNER" collection show "$COLLECTION_NAME" 2>/dev/null || true)"
  grep -F "Path:     $README_DIR" <<<"$show_output" >/dev/null
}

embedding_state_missing_or_invalid() {
  if [[ ! -f "$EMBED_STATE_FILE" ]]; then
    return 0
  fi

  local embedded_at
  embedded_at="$(tr -d '[:space:]' < "$EMBED_STATE_FILE")"
  [[ ! "$embedded_at" =~ ^[0-9]+$ ]]
}

refresh_embeddings() {
  local pending_before pending_after pass
  log "Refreshing QMD embeddings for index '$INDEX_NAME'..."
  "$MODEL_RUNNER" --mode embed

  pending_before="$(get_pending_embedding_count)"
  if (( pending_before == 0 )); then
    write_timestamp "$EMBED_STATE_FILE"
    log "QMD embeddings are already current."
    return
  fi

  pass=0
  while (( pending_before > 0 )); do
    pass=$((pass + 1))
    log "Embedding pass $pass: ${pending_before} documents still need vectors..."
    "$QMD_RUNNER" embed >/dev/null
    pending_after="$(get_pending_embedding_count)"

    if (( pending_after == 0 )); then
      write_timestamp "$EMBED_STATE_FILE"
      log "QMD embeddings are up to date."
      return
    fi

    if (( pending_after >= pending_before )); then
      log "QMD embed stalled: ${pending_after} documents still need vectors after pass $pass."
      return 1
    fi

    pending_before="$pending_after"
  done
}

should_refresh=0
refresh_reason=""
now="$(date +%s)"

if (( FORCE_REFRESH )); then
  should_refresh=1
  refresh_reason='user requested refresh'
elif [[ ! -f "$STATE_FILE" ]]; then
  should_refresh=1
  refresh_reason='first use'
elif [[ ! -f "$README_DIR/.index.tsv" ]]; then
  should_refresh=1
  refresh_reason='missing README fetch snapshot'
else
  last_indexed_at="$(tr -d '[:space:]' < "$STATE_FILE")"
  if [[ ! "$last_indexed_at" =~ ^[0-9]+$ ]]; then
    should_refresh=1
    refresh_reason='invalid refresh timestamp'
  elif (( now - last_indexed_at >= FRESHNESS_SECONDS )); then
    should_refresh=1
    refresh_reason='cache older than 7 days'
  fi
fi

should_embed=0
embed_reason=''
created_collection=0

if (( should_refresh )); then
  should_embed=1
  embed_reason="$refresh_reason"
  log "Refreshing Pi package README cache (${refresh_reason})..."
  OUT_DIR="$README_DIR" "$SCRIPT_DIR/fetch_pi_package_readmes.sh"
elif embedding_state_missing_or_invalid; then
  should_embed=1
  embed_reason='missing or invalid embedding timestamp'
fi

if collection_exists && ! collection_points_to_readmes; then
  log "Recreating QMD collection '$COLLECTION_NAME' because it points somewhere else..."
  "$QMD_RUNNER" collection remove "$COLLECTION_NAME" >/dev/null
fi

if ! collection_exists; then
  log "Creating QMD collection '$COLLECTION_NAME'..."
  "$QMD_RUNNER" collection add "$README_DIR" --name "$COLLECTION_NAME" --mask '**/*.md' >/dev/null
  created_collection=1
  should_embed=1
  if [[ -z "$embed_reason" ]]; then
    embed_reason='new collection'
  fi
fi

if (( should_refresh )) && (( ! created_collection )); then
  log "Updating QMD index '$INDEX_NAME'..."
  "$QMD_RUNNER" update >/dev/null
fi

if (( should_embed )); then
  log "Preparing hybrid query support (${embed_reason})..."
  refresh_embeddings
fi

if (( should_refresh )); then
  write_timestamp "$STATE_FILE"
  log "QMD index '$INDEX_NAME' is up to date."
elif (( created_collection )); then
  log "QMD collection '$COLLECTION_NAME' is ready."
fi