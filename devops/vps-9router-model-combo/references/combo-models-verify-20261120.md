# 9router Combo Model Verification — Session Detail (2026-11-20)

Class-level technique for discovering, verifying, and changing model combos in the 9router Docker container on a remote VPS. This file records the session-specific findings and the corrected verification method for this class of task.

## User Preferences
- Bahasa Indonesia unless explicitly switched to English. Keep answers short and targeted; no long explanations.
- When asked to "cek/model", default to Indonesia.

## Findings from this session

### 1. Combo 9router yang aktif
Hanya ada **1 combo aktif**:
```
9router-combo (id: 74285da3-fe7e-447b-b873-862bcf8f7f47)
Model: oc/minimax-m3.1-flash-free | oc/big-pickle | oc:deepseek-v4.1-flash-free | oc:glm-5.3-flash-free
```

### 2. Model dalam combo
| Model | Status |
|---|---|
| oc/minimax-m3.1-flash-free | OK, aktif |
| oc/big-pickle | OK, aktif |
| oc:deepseek-v4.1-flash-free | OK, aktif |
| oc:glm-5.3-flash-free | OK, aktif |

### 3. Tempat model `oc:*` di simpan
Model `oc:*` (local adapter) **tidak** ada di `model-catalog.json` (6446 model). Mereka ada di SQLite `db` (table `kv`) dengan key format `oc|<id>|llm`. Contoh:
```
oc|big-pickle|llm       => {"providerAlias":"oc","id":"big-pickle","type":"llm","name":"big-pickle"}
oc|deepseek-v4.1-flash-free|llm => {"providerAlias":"oc","id":"deepseek-v4.1-flash-free","type":"llm","name":"deepseek-v4.1-flash-free"}
oc|glm-5.3-flash-free|llm => {"providerAlias":"oc","id":"glm-5.3-flash-free","type":"llm","name":"glm-5.3-flash-free"}
oc|minimax-m3.1-flash-free|llm => {"providerAlias":"oc","id":"minimax-m3.1-flash-free","type":"llm","name":"minimax-m3.1-flash-free"}
```

### 4. Catatan penting
- `providerNodes` dan `proxyPools` tabel **kosong**.
- Provider koneksi yang tersedia: `openrouter` (active), `poolside` (active), `gemini` (unavailable / 502 timeout).
- Combo ini dipakai lewat provider `opencode` (bukan provider node terpisah).
- Dari `usageHistory` 19–20 Nov 2026, semua 4 model combo punya request berjalan dengan status `ok` → semua dapat digunakan.

## Corrected verification method (per this session)
Model dalam combo **tidak** dicek di `model-catalog.json` (karena `oc:*` tidak ada di sana). Pengecekan yang benar:
1. Baca `combos` dari SQLite (table `combos`, columns `id, name, kind, models, createdAt, updatedAt`).
2. Periksa tiap model di `kv` (table `kv`, key `oc|<id>|llm`).
3. Cross-check `usageHistory` untuk konfirmasi model pernah/ sedang digun(nakan dengan status `ok`.

Pitfall yang direkam:
- **Jangan asumsikan** semua model combo ada di `model-catalog.json`. Model `oc:*` hanya ada di `kv`.
- model-catalog.json hanya berisi 6446 model dari **48 provider**, sedangkan combo bisa menyertakan model lokal (`oc:*`).
