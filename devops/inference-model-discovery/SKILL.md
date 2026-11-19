---
name: inference-model-discovery
description: Finding, filtering, and verifying free/inference models on a Hermes agent or local setup (config.yaml, cache, live API)
category: devops
created: 2026-11-13
updated: 2026-11-13
---

# Inference Model Discovery

## Overview
How to find the currently active free model and discover other free models available on a Hermes agent setup. Covers local config cache, provider definitions, and live API verification.

## Trigger Conditions
- User says "cek model", "model free", "model apa yang bisa", "model yang gratis", or asks about available/inference models
- User asks which model is active by default
- User wants alternatives to the current model

## Language Preference (EMBED THIS)
- **DEFAULT LANGUAGE: Indonesia** when the user indicates preference with "gunakan bahasa indonesia" or similar. Switch to English only if the user explicitly requests or switches mid-conversation.
- **Concise, targeted answers.** Do not narrate every command you run; report the result directly. If there are multiple steps, batch them into one command. Only explain when the user asks.

## Core Workflow
### 1. Find the active default model
Read `config.yaml` (top of file):
```
model:
  default: <model>
  provider: <provider>
  base_url: <url>
```
This is the single source of truth for what the agent is currently using.

### 2. List models offered by the active provider
Providers define models in two places:
- `config.yaml` under a `custom_providers` entry, in the `models:` list.
- A live provider API endpoint (e.g. `https://inference-api.nousresearch.com/v1/models`).

**Default model = cached list, not live list.** A default model does NOT have a `/v1/models` endpoint you can query live — that endpoint is the `/v1` INFERENCE endpoint of the default provider. The list of free models for the default provider comes directly from `GET <base_url>/v1/models`.

### 3. Find "free" models
Search for models whose id/description contains `-free`, `:free`, or `free` in:
- `config.yaml` custom provider lists (suffix-free markers)
- `models_dev_cache.json` (per-provider model records with `free` in id/desc)
- `cache/model_catalog.json` (OpenRouter curated list filtered by free pricing)
- `ollama_cloud_models_cache.json` (Ollama cloud model slugs)

### 4. Verify free models against the live default-provider list (required)
Cache markers (`-free`, `:free`) are **not all usable**. The environment changes, and a cached slug may no longer exist on the live provider. Therefore:
1. **Run the live API list** → `curl -s https://<provider>/v1/models > /tmp/models.json`
2. **Parse from the live list only** (not .json cache) using `execute_code` → filter id/description containing `-free`, `:free`, or `free`
3. Return the filtered list.

The **default provider's `/v1/models` is the authoritative list of current free models** — this is the same list the cache files approximate but never contain. Cash-cache files exist mainly for other providers. If API returns 404, try the base URL directly: `curl -s <base_url>/v1/models`.

## Common Pitfalls
- **Treating cache markers as live truth.** A `-free` slug in `config.yaml` or `models_dev_cache.json` may be stale. Verify against the live API when accuracy matters.
- **No consent for live API reads.** If a command hits an external API with a bearer token, the user must consent before it runs. If blocked/consented, use a lightweight `curl` instead of chaining into `python3`.
- **Secrets are masked.** `config.yaml` and `auth.json` contain real tokens. Never print them; only reference paths.
- **Distinguish "free tier" from "free to use".** Some `free` entries are older legacy compat entries, not current free tiers.
- **The default provider CAN be queried live.** `GET <base_url>/v1/models` is valid for the default provider (e.g. `https://inference-api.nousresearch.com/v1/models`) — this is the correct way to check its free models. A default model itself does not have a `/v1/models` endpoint you can query live; the base URL does.

## Support Files
- `references/model-cache-explorer.md` — condensed map of where free-model markers live across local cache files, so future sessions do not re-hunt them.
