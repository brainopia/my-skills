#!/usr/bin/env bash
set -euo pipefail

MODEL_CACHE_DIR="${PI_SEARCH_PACKAGES_QMD_MODEL_CACHE_DIR:-$HOME/.cache/qmd/models}"
EMBED_MODEL_URI="${QMD_EMBED_MODEL:-hf:ggml-org/embeddinggemma-300M-GGUF/embeddinggemma-300M-Q8_0.gguf}"
RERANK_MODEL_URI="${PI_SEARCH_PACKAGES_QMD_RERANK_MODEL:-hf:ggml-org/Qwen3-Reranker-0.6B-Q8_0-GGUF/qwen3-reranker-0.6b-q8_0.gguf}"
GENERATE_MODEL_URI="${PI_SEARCH_PACKAGES_QMD_GENERATE_MODEL:-hf:tobil/qmd-query-expansion-1.7B-gguf/qmd-query-expansion-1.7B-q4_k_m.gguf}"
MODE="query"
FORCE_REFRESH=0

usage() {
  cat <<'EOF'
Usage: ensure_pi_package_qmd_models.sh [options]

Ensures the QMD models required by this skill are present in ~/.cache/qmd/models.
Each missing model is downloaded with node-llama-cpp's interactive progress bar.

Options:
  --mode <embed|query|all>  Which model set to ensure (default: query)
  --refresh                 Re-download models even if they already exist
  -h, --help                Show this help text
EOF
}

while (($# > 0)); do
  case "$1" in
    --mode)
      MODE="$2"
      shift 2
      ;;
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

mkdir -p "$MODEL_CACHE_DIR"

pull_model() {
  local label="$1"
  local uri="$2"
  local args=(npx -y node-llama-cpp pull --directory "$MODEL_CACHE_DIR")

  if (( FORCE_REFRESH )); then
    args+=(--override)
  fi

  printf '\n==> Ensuring %s\n' "$label"
  printf '    %s\n' "$uri"
  "${args[@]}" "$uri"
}

case "$MODE" in
  embed)
    pull_model "embedding model" "$EMBED_MODEL_URI"
    ;;
  query|all)
    pull_model "embedding model" "$EMBED_MODEL_URI"
    pull_model "query expansion model" "$GENERATE_MODEL_URI"
    pull_model "reranking model" "$RERANK_MODEL_URI"
    ;;
  *)
    printf 'Unsupported mode: %s\n' "$MODE" >&2
    usage >&2
    exit 1
    ;;
esac
