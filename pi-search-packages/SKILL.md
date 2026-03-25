---
name: pi-search-packages
description: Search npm packages tagged pi-package by their cached README content. Use when someone wants to discover Pi packages by capability, compare Pi package READMEs, inspect package docs, or refresh the local Pi package README index.
---

# Pi Search Packages

Search Pi packages by the contents of their npm README files.

## What this skill owns

- Downloads README content for every npm package tagged `pi-package`.
- Stores the downloaded README files under `~/.pi/cache/pi-search-packages/readmes`.
- Indexes that cache with QMD under the named index `pi-search-packages`.
- Refreshes automatically on first use, whenever the cache is older than 7 days, or whenever the user explicitly asks for a refresh/reindex/update.
- Maintains QMD embeddings so searches can run through `qmd query` instead of plain BM25 search.

## When to refresh

Run `scripts/ensure_pi_package_readmes_index.sh --refresh` when the user explicitly asks to refresh, reindex, resync, or update the Pi package README cache.

For ordinary search requests, do not refresh manually first. Run the search script directly and let it decide:

```bash
./scripts/search_pi_package_readmes.sh --format json "package for markdown search"
```

It will refresh automatically on first use or when the last successful refresh is more than 7 days old.

## Search workflow

1. Choose search terms that describe the capability you want, even if the exact README wording might differ.
2. Run the search script with JSON output so `qmd query` can return structured hybrid-search results.
3. If you need the full README for a result, use the `file` URI returned by QMD with `qmd get`, or open the corresponding cached file under `~/.pi/cache/pi-search-packages/readmes/`.

### Standard search

```bash
./scripts/search_pi_package_readmes.sh --format json "vector search for markdown"
```

### Higher recall search

```bash
./scripts/search_pi_package_readmes.sh --limit 25 --min-score 0.15 --format json "package for skill creation"
```

### Explicit refresh without searching

```bash
./scripts/ensure_pi_package_readmes_index.sh --refresh
```

### Inspect index health

```bash
./scripts/run_pi_package_qmd.sh status
```


### Inspect a specific indexed README after search

```bash
./scripts/run_pi_package_qmd.sh get "qmd://pi-package-readmes/pi-agent-browser.md" --full
```

## Bundled scripts

- `scripts/fetch_pi_package_readmes.sh` — fetches README files for every npm package tagged `pi-package`, incrementally.
- `scripts/ensure_pi_package_readmes_index.sh` — enforces first-run/7-day/forced refresh policy and keeps the QMD collection aligned with the cache path.
- `scripts/ensure_pi_package_qmd_models.sh` — checks the required QMD models and downloads any missing ones with a visible progress bar for each model.
- `scripts/run_pi_package_qmd.sh` — runs QMD against the `pi-search-packages` index with safe runtime defaults for this environment.
- `scripts/search_pi_package_readmes.sh` — refreshes when needed, prefetches query models when needed, then runs `qmd query` against the indexed README collection.

## Notes

- Search uses `qmd query` so results can benefit from query expansion, vector retrieval, and reranking.
- The first time a required model is missing, the skill downloads it up front with `node-llama-cpp pull` so progress is visible instead of appearing to hang inside `qmd query` or `qmd embed`.
- The ensure script keeps embeddings current so new or changed README files participate in hybrid search.
- QMD caps one embedding session at 30 minutes internally; the ensure script now reruns `qmd embed` until pending documents reach zero or progress stalls, so large README corpora finish across multiple passes instead of silently claiming success too early.
- `run_pi_package_qmd.sh` unsets `CI` so `qmd query` is allowed to run LLM steps in this harness, and defaults `NODE_LLAMA_CPP_GPU=false` so QMD stays on CPU instead of repeatedly failing Vulkan auto-builds on this machine. Override with `PI_SEARCH_PACKAGES_QMD_GPU=auto` or another supported node-llama-cpp GPU mode if you have a working local GPU backend.
- The refresh timestamp is written only after the README fetch, QMD indexing, and embedding steps succeed.
- The QMD collection name is `pi-package-readmes`; the named index is `pi-search-packages`.
