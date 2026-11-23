---
name: 9router-management
description: Manage and troubleshoot 9Router containerized LLM gateway.
---

# 9Router Troubleshooting Workflow

Use this skill when diagnosing 9Router container issues, routing failures, or performance bottlenecks.

## Core Procedures

### 1. Diagnose Routing Status
Always check container logs to identify stuck models or rate-limiting:
```bash
docker logs --tail 200 9router | grep -E "\[COMBO\]|▶ POST|ERROR"
```
*   `[COMBO] Trying model`: Shows the fallback attempt order.
*   `ERROR 429`: Indicates rate-limiting on a provider (e.g., OpenRouter shared pool).
*   `▶ POST`: Shows active requests to specific model endpoints.

### 2. Troubleshoot Failover
If the system is stuck on one model despite errors:
1. Identify the stuck model via logs.
2. Check if "Smart Router" is reporting "no decision" — if yes, the system falls back to the manual order.
3. Restart the container if the circuit breaker appears hung: `docker restart 9router`.

### 3. Adjust Model Priority
*   **Via UI (Recommended):** Dashboard (`http://<IP>:20128`) -> Router/Combo Settings. Drag-and-drop to adjust fallback order.
*   **Via Provider:** Add a personal API Key for frequently rate-limited providers (e.g., OpenRouter) to bypass shared pool restrictions.

## Pitfalls
*   **Do not rely on `model-catalog.json` for routing priority:** This file is a catalog, not a configuration file for fallback order.
*   **Rate limits (429) are upstream:** If a provider (e.g., Poolside via OpenRouter) returns 429, the gateway *should* switch to the next model in the fallback list. If it does not, the circuit breaker logic in the container may be hung; restart is required.
