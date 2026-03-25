#!/usr/bin/env bash
set -euo pipefail

INDEX_NAME="${PI_SEARCH_PACKAGES_QMD_INDEX:-pi-search-packages}"
GPU_MODE="${PI_SEARCH_PACKAGES_QMD_GPU:-false}"

exec env -u CI NODE_LLAMA_CPP_GPU="$GPU_MODE" npx -y @tobilu/qmd --index "$INDEX_NAME" "$@"
