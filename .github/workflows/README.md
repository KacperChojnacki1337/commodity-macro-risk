# CI/CD workflows

GitHub Actions that guard `main`. Each `.yml` here is an independent workflow.

## Workflows

| File | Trigger | What it does | Needs secrets? |
|------|---------|--------------|----------------|
| `ci.yml` | every PR to `main` + push to `main` | `validate-sources` (sources.json valid + required shape) and `terraform` (fmt-check + validate for dev & prod) | no |
| `dbt-ci.yml` | PR/push touching `dbt/**` (+ manual) | Builds the dbt project against the **dev** target. Skips cleanly if the dbt project or the Snowflake secrets are missing. | yes (Snowflake) |
| `sync-control-metadata.yml` | push to `main` touching `ingestion/control/sources.json` (+ manual) | Uploads `sources.json` to the ADLS `config` container, so ADF executes what the repo says. Skips cleanly if Azure isn't configured. | **no** — OIDC |

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
| `SNOWFLAKE_ROLE` | `ACCOUNTADMIN` (until `ROLE_LOADER` exists, #10) |
| `SNOWFLAKE_WAREHOUSE` | `WH_XS_ELT` |
| `SNOWFLAKE_DATABASE` | `COMMODITY_RISK` |

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
