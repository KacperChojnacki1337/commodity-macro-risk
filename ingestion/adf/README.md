# Azure Data Factory — as code

Exported ARM template of the Data Factory (pipelines, datasets, linked
services). This is the "ADF as code" artifact: the whole factory can be
redeployed from here after a `terraform destroy` or on a fresh Azure trial.

## Files

| File | Purpose |
|------|---------|
| `ARMTemplateForFactory.json` | All factory objects (linked services, datasets, pipeline). |
| `ARMTemplateParametersForFactory.json` | Parameter values (factory name, ADLS URL). |

## What's inside

- **Linked services:** `ls_adls_raw` (ADLS Gen2 via the factory's managed
  identity), `ls_http_nbp` (HTTP, anonymous, parameterized `baseUrl`).
- **Datasets:** `ds_config_sources` (reads `sources.json`), `ds_src_http_bin`
  (parameterized HTTP source, Binary), `ds_raw_sink_bin` (parameterized ADLS
  sink, Binary).
- **Pipeline `pl_ingest_source`** (metadata-driven):
  `Lookup(sources.json)` -> `Filter(enabled)` -> `ForEach` -> `Copy`.
  Landing path/file are built from each source's templates with the run date
  substituted for `{ingest_date}`, so re-runs overwrite the day's partition
  (idempotent). Adding a source = a new entry in
  [../control/sources.json](../control/sources.json), not a new pipeline.

## No secrets

The template contains no credentials. HTTP is anonymous; ADLS auth is the
factory's managed identity (granted `Storage Blob Data Contributor` via
Terraform). The only parameter values are resource names/URLs.

## Redeploy

`sources.json` must exist in the storage `config` container first, then deploy
the template to a factory (parameter values are environment-specific — the
committed defaults point at the current dev factory):

```bash
az deployment group create \
  --resource-group <rg> \
  --template-file ARMTemplateForFactory.json \
  --parameters @ARMTemplateParametersForFactory.json \
  --parameters factoryName=<target-factory-name>
```

> Authoring is done in ADF Studio ("Data Factory" mode), then **Export ARM
> template** and committed here via a PR. Git integration inside ADF is
> intentionally not used, to keep the protected-`main` PR flow clean.
