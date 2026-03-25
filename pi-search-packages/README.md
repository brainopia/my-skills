# pi-search-packages

A Pi agent skill that caches README files for every npm package tagged `pi-package`, reindexes them with QMD, and searches those README files locally with `qmd query`.

## Installation

```bash
pi install /absolute/path/to/pi-search-packages
```

## What it does

- Downloads package README files into `~/.pi/cache/pi-search-packages/readmes`
- Refreshes automatically on first use and every 7 days after the last successful refresh
- Supports explicit refresh requests
- Searches the indexed README cache with `./scripts/run_pi_package_qmd.sh query ...`
- Maintains QMD embeddings so hybrid search stays current after refreshes
- Downloads missing QMD models up front with visible progress bars before `qmd query` or `qmd embed` would otherwise stall silently
- Unsets `CI` for QMD and defaults `NODE_LLAMA_CPP_GPU=false`, so `qmd query` can run here without tripping over CI-mode LLM blocks or broken Vulkan auto-detection
- Uses local QMD models, so the first full setup can be slower than later searches
- Retries `qmd embed` in multiple passes when the corpus is too large for QMD's single-session time limit, and only records embedding success once pending documents reach zero