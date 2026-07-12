# Ingestion control metadata

`sources.json` is the **control file** that drives metadata-driven ingestion.
Azure Data Factory reads it with a Lookup activity, then a ForEach iterates the
enabled sources and calls one generic, parameterized child pipeline. Adding a
new source = adding one object here — no new pipeline.

## Field reference

| Field | Meaning |
|-------|---------|
| `source_id` | Short identifier (e.g. `nbp`); also used in the ADLS path. |
| `enabled` | `true`/`false`. ForEach processes only enabled sources. A kill switch. |
| `description` | Human-readable description of the source. |
| `base_url` | API endpoint the pipeline calls. |
| `auth_type` | `none` / `api_key` / `header`. How to authenticate. |
| `secret_name` | **Name** of the Key Vault secret (never the secret value). `null` if keyless. |
| `http_method` | HTTP verb, usually `GET`. |
| `response_format` | `json` / `csv`. What the pipeline expects back. |
| `frequency` | `daily` / `monthly` / `quarterly`. Drives scheduling and later reconciliation. |
| `landing_container` | ADLS container to write into (e.g. `raw`). |
| `landing_path_template` | Path within the container; `{ingest_date}` is substituted at runtime. |
| `file_name_template` | Output file name; `{ingest_date}` substituted at runtime. |
| `incremental_strategy` | `full_snapshot` or an incremental strategy. |
| `date_window_days` | Max days per API request (for range/backfill limits). |
| `notes` | Gotchas and reminders. |

## Rules

- **No secrets in this file.** Only `secret_name` pointers to Key Vault.
- Keep it valid JSON; it is validated in CI.
- One object per source under `sources`.
