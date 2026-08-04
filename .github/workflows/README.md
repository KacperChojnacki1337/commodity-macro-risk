# CI/CD workflows

GitHub Actions that guard `main`. Each `.yml` here is an independent workflow.

## Workflows

| File | Trigger | What it does | Needs secrets? |
|------|---------|--------------|----------------|
| `ci.yml` | every PR to `main` + push to `main` | `validate-sources` (sources.json valid + required shape) and `terraform` (fmt-check + validate for dev & prod) | no |
| `dbt-ci.yml` | **PR** touching `dbt/**` (+ manual) | Builds the dbt project against the **dev** target (the zero-copy clone) — tests changes before merge. Skips cleanly if the dbt project or Snowflake secrets are missing. | yes (Snowflake) |
| `dbt-deploy-prod.yml` | **push to `main`** touching `dbt/**`, **+ daily cron 06:00 UTC** (+ manual) | Deploys models to **prod** (`dbt build --target prod`) on merge, and **runs daily** to refresh marts (incl. the Eurostat snapshot) from freshly-loaded bronze. Skips cleanly if secrets absent. | yes (Snowflake) |
| `sync-control-metadata.yml` | push to `main` touching `ingestion/control/sources.json` (+ manual) | Uploads `sources.json` to the ADLS `config` container, so ADF executes what the repo says. Skips cleanly if Azure isn't configured. | **no** — OIDC |
| `deploy-adf.yml` | push to `main` touching `ingestion/adf/**` (+ manual) | Deploys the ADF ARM template (pipeline, datasets, linked services, **daily ScheduleTrigger**) to the live factory and stops/starts the trigger around the deploy — no manual Studio redeploy. Skips cleanly if Azure isn't configured. | **no** — OIDC |

`ci.yml` needs no cloud access — Terraform `validate` and JSON checks run
offline — so it stays green from day one. `validate-sources` and `terraform`
are **required status checks** for merging into `main`.

## Secrets (repo Settings → Secrets and variables → Actions)

Currently configured (used by `dbt-ci.yml`):

| Secret | Value / meaning |
|--------|-----------------|
| `SNOWFLAKE_ACCOUNT` | account identifier, `ORG-ACCOUNT` form |
| `SNOWFLAKE_USER` | Snowflake login |
| `SNOWFLAKE_PASSWORD` | password (secret) |
| `SNOWFLAKE_ROLE` | `ROLE_LOADER` (least-privilege write role; owns BRONZE/STAGING/MARTS) |
| `SNOWFLAKE_WAREHOUSE` | `WH_XS_ELT` |
| `SNOWFLAKE_DATABASE` | `COMMODITY_RISK` |
| `HEALTHCHECK_URL` | *(optional)* healthchecks.io ping URL — the daily `dbt-deploy-prod` run pings it as a **dead-man's switch** (see below) |

**Never commit secret values.** Reference them as `${{ secrets.NAME }}` only.

## Variables (not secrets)

`sync-control-metadata.yml` authenticates to Azure with **OIDC**, so there is no
Azure password/secret anywhere. What it needs are plain identifiers, stored as
repo **Variables** (readable by design — they are useless without the federated
trust):

| Variable | Meaning |
|----------|---------|
| `AZURE_CLIENT_ID` | App registration (`gh-actions-commodity-macro-risk`) client ID |
| `AZURE_TENANT_ID` | Azure AD tenant |
| `AZURE_SUBSCRIPTION_ID` | Target subscription |
| `ADLS_STORAGE_ACCOUNT` | Storage account holding the `config` container (name carries a random suffix — update after re-pinning to a new trial) |
| `AZURE_RESOURCE_GROUP` | Resource group holding the Data Factory (used by `deploy-adf.yml` to deploy the ARM and start the trigger) |

### How the secretless Azure login works

1. The workflow requests a short-lived **OIDC token** from GitHub
   (`permissions: id-token: write`).
2. Azure AD has a **federated credential** on the app that trusts
   `repo:<owner>/<repo>:ref:refs/heads/main` from GitHub's issuer — so the token
   is accepted **only** for this repo's `main` branch.
3. The app's service principal holds **Storage Blob Data Contributor scoped to
   the `config` container only** — it cannot touch the `raw` data zone.

Nothing long-lived is stored, so there is no Azure credential to leak or rotate.
Re-create with `az ad app create` + `az ad app federated-credential create` when
rebuilding on a fresh trial (then update `AZURE_CLIENT_ID` /
`ADLS_STORAGE_ACCOUNT`).

> All six Snowflake secrets are set deliberately, even though
> `profiles.example.yml` has defaults like `env_var('SNOWFLAKE_ROLE',
> 'ACCOUNTADMIN')`. A missing secret resolves to an **empty string**, not to
> "unset" — and `env_var` only falls back to its default when the variable is
> unset. Empty is not absent.

## Dead-man's switch (why `HEALTHCHECK_URL`)

GitHub **automatically disables a scheduled workflow after 60 days with no repo
activity**. That would silently stop the daily `dbt-deploy-prod` run — and with
it the `dbt source freshness` staleness gate, i.e. the safety net itself goes
dark with no signal.

To catch that, the daily run pings an external healthcheck (e.g.
[healthchecks.io](https://healthchecks.io), free) on every run: the ping URL on
success, `<url>/fail` on failure. If the run stops (disabled) or fails, the
**missing** ping makes the external monitor email you. Set `HEALTHCHECK_URL` to
enable it; without it the step is a no-op.

## Operational note: when a trial expires

`dbt-ci.yml` skips when the Snowflake secrets are **absent**, but runs (and
would fail) when they are present and the warehouse is gone.

**Before the Snowflake trial expires, delete the secrets** so the workflow goes
back to skipping and the repo stays green for anyone browsing it:

```bash
for s in SNOWFLAKE_ACCOUNT SNOWFLAKE_USER SNOWFLAKE_PASSWORD \
         SNOWFLAKE_ROLE SNOWFLAKE_WAREHOUSE SNOWFLAKE_DATABASE; do
  gh secret delete "$s"
done
```

Re-add them (same names) after rebuilding on a fresh trial.
