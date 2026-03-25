#!/usr/bin/env bash
set -euo pipefail

# Fetch README.md for all npm packages tagged with keyword:pi-package.
# Repeat runs are optimized:
# - only packages whose publish date changed since last run are processed (OUT_DIR/.index.tsv)
# - per-package fetch uses conditional GET (ETag) to avoid re-downloading unchanged metadata.
#
# Requirements: curl, jq, xargs

REGISTRY_BASE_URL="${REGISTRY_BASE_URL:-https://registry.npmjs.org}"
QUERY_TEXT="${QUERY_TEXT:-keywords:pi-package}"
OUT_DIR="${OUT_DIR:-$HOME/.pi/cache/pi-search-packages/readmes}"
PAGE_SIZE="${PAGE_SIZE:-250}"         # npm search API supports up to 250
PARALLELISM="${PARALLELISM:-20}"

mkdir -p "$OUT_DIR"

search_page() {
  local from="$1"
  curl -fsS --retry 5 --retry-all-errors --connect-timeout 10 --max-time 60 \
    "$REGISTRY_BASE_URL/-/v1/search?text=$(printf '%s' "$QUERY_TEXT" | jq -sRr @uri)&size=$PAGE_SIZE&from=$from"
}

# 1) Determine total count
TOTAL="$(
  curl -fsS --retry 5 --retry-all-errors --connect-timeout 10 --max-time 60 \
    "$REGISTRY_BASE_URL/-/v1/search?text=$(printf '%s' "$QUERY_TEXT" | jq -sRr @uri)&size=1&from=0" \
  | jq -r '.total'
 )"

# Index of last seen publish date per package (so repeat runs only fetch changed/new packages)
INDEX_FILE="$OUT_DIR/.index.tsv"

SNAPSHOT_FILE="$(mktemp)"
CHANGED_FILE="$(mktemp)"
cleanup() {
  rm -f "$SNAPSHOT_FILE" "$CHANGED_FILE"
}
trap cleanup EXIT

# 2) Build snapshot (name<TAB>date) for all results (handles growth in total count)
(
  from=0
  while [ "$from" -lt "$TOTAL" ]; do
    search_page "$from" \
      | jq -r '.objects[] | [.package.name, (.package.date // "")] | @tsv'
    from=$((from + PAGE_SIZE))
  done
) \
| awk -F'\t' '{ if ($2 == "") $2 = "1970-01-01T00:00:00.000Z"; print $1"\t"$2 }' \
| sort -t$'\t' -k1,1 -u \
> "$SNAPSHOT_FILE"

# 3) Determine which packages changed since last run (new package or publish date changed)
if [ -f "$INDEX_FILE" ]; then
  awk -F'\t' 'NR==FNR{old[$1]=$2;next} !($1 in old) || old[$1]!=$2 {print $1}' \
    "$INDEX_FILE" "$SNAPSHOT_FILE" > "$CHANGED_FILE"
else
  cut -f1 "$SNAPSHOT_FILE" > "$CHANGED_FILE"
fi

# 4) Fetch README only for changed packages (still uses ETag to avoid re-downloading metadata if unchanged)
cat "$CHANGED_FILE" \
| xargs -r -n1 -P "$PARALLELISM" bash -lc '
  set -euo pipefail
  REGISTRY_BASE_URL="$1"
  OUT_DIR="$2"
  name="$3"
  # Map package name -> output path
  if [[ "$name" == @*/* ]]; then
    scope="${name%%/*}"   # @scope
    pkg="${name##*/}"     # name
    mkdir -p "$OUT_DIR/$scope"
    out="$OUT_DIR/$scope/$pkg.md"
  else
    out="$OUT_DIR/$name.md"
  fi
  etag_file="$out.etag"
  # URL encode package name (needed for @scope/name)
  enc="$(printf "%s" "$name" | jq -sRr @uri)"
  url="$REGISTRY_BASE_URL/$enc"
  tmp_h="$(mktemp)"
  tmp_b="$(mktemp)"
  etag=""
  if [ -f "$etag_file" ]; then
    etag="$(cat "$etag_file" || true)"
  fi
  # Fetch package metadata JSON with conditional request if we have ETag.
  # We need headers to detect 304 Not Modified.
  if [ -n "$etag" ]; then
    http_code="$(curl -sS -D "$tmp_h" -o "$tmp_b" -w "%{http_code}" \
      --retry 5 --retry-all-errors --connect-timeout 10 --max-time 60 \
      -H "If-None-Match: $etag" \
      "$url" || true)"
  else
    http_code="$(curl -sS -D "$tmp_h" -o "$tmp_b" -w "%{http_code}" \
      --retry 5 --retry-all-errors --connect-timeout 10 --max-time 60 \
      "$url" || true)"
  fi
  # curl error -> http_code may be empty
  if [ -z "$http_code" ]; then
    printf "FETCH FAILED: %s\n" "$url" > "$out"
    rm -f "$tmp_h" "$tmp_b"
    exit 0
  fi
  if [ "$http_code" = "304" ]; then
    # Unchanged: keep existing README and ETag
    rm -f "$tmp_h" "$tmp_b"
    exit 0
  fi
  if [ "$http_code" != "200" ]; then
    printf "HTTP %s while fetching %s\n" "$http_code" "$url" > "$out"
    rm -f "$tmp_h" "$tmp_b"
    exit 0
  fi
  # Extract README text
  jq -r ".readme // \"NO README\"" < "$tmp_b" > "$out"
  # Save new ETag (if present)
  new_etag="$(grep -i "^etag:" "$tmp_h" | head -n1 | sed -E "s/^[Ee][Tt][Aa][Gg]:[[:space:]]*//" | tr -d "\r")"
  if [ -n "$new_etag" ]; then
    printf "%s" "$new_etag" > "$etag_file"
  fi

  rm -f "$tmp_h" "$tmp_b"
' _ "$REGISTRY_BASE_URL" "$OUT_DIR"

# 5) Persist new snapshot only after successful run
mv "$SNAPSHOT_FILE" "$INDEX_FILE"
# prevent trap from deleting the moved file
SNAPSHOT_FILE=""
