# Model Cache Explorer

Condensed map of where "free"/inference model markers live across local cache files on a Hermes agent setup. Use this as a quick lookup before re-hunting files.

## 1. `config.yaml` — ACTIVE PROVIDER LIST
- Path: `/root/.hermes/config.yaml`
- Relevant section: top `model:` block + `custom_providers:` list
- The `custom_providers[].models` list is authoritative for what the agent is allowed to route to.
- Free-marker examples seen:
  - `oc/muse-spark-1.2-contributor-free`
  - `oc/muse-spark-1.3-contributor-free`
  - `oc/jev-1.13-free`
  - `oc/glm-5.3-flash-free`
  - `oc/deepseek-v4.1-flash-free`
  - `oc/nemotron-3.5-super-vl-free`

## 2. `models_dev_cache.json` — PER-PROVIDER MODEL RECORDS
- Path: `/root/.hermes/models_dev_cache.json`
- Huge multi-MB file. Filter by active provider key first (e.g. `data['nous']` if it exists).
- Search fields: `id`, `name`, `description`. Free markers: `-free`, `:free`, `free`.
- Note: the `nous` key was NOT found in this cache at time of inspection (provider name may be stored differently in the cache).

## 3. `cache/model_catalog.json` — OPENROUTER CURATED LIST
- Path: `/root/.hermes/cache/model_catalog.json`
- Structure: `providers -> openrouter -> models[] -> id, description`
- Filtered by `free` pricing in the `metadata.note` text. Describes the curated list, not live availability.

## 4. `ollama_cloud_models_cache.json` — OLLAMA CLOUD MODEL SLUGS
- Path: `/root/.hermes/ollama_cloud_models_cache.json`
- Structure: `{"models": [...], "cached_at": ...}`
- Slugs like `deepseek-v4.1-flash`, `glm-5.3-flash`, `minimax-m3.1-flash`, `mimo-v2.6-flash` (no `-free` suffix in this file).

## 5. Live API — `GET /v1/models`
- Endpoint: `https://inference-api.nousresearch.com/v1/models`
- Response: JSON `{"data": [...]}` with `id`, `pricing`, `context_length`, etc.
- This is the only source of truth for **what is reachable right now**.
- Key rule: cache markers (`-free`, `:free`) are **stale by default**. Verify the exact `id` against this response before recommending.
