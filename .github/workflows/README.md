# CI/CD workflows

GitHub Actions that guard `main`. Each `.yml` here is an independent workflow.

## Workflows

| File | Trigger | What it does | Needs secrets? |
|------|---------|--------------|----------------|
| `ci.yml` | every PR to `main` + push to `main` | `validate-sources` (sources.json valid + required shape) and `terraform` (fmt-check + validate for dev & prod) | no |
| `dbt-ci.yml` | PR/push touching `dbt/**` (+ manual) | Builds the dbt project against the **dev** target. Skips cleanly if the dbt project or the Snowflake secrets are missing. | yes (Snowflake) |

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

Not needed yet: `ARM_SUBSCRIPTION_ID` / `ARM_TENANT_ID` / `ARM_CLIENT_ID` /
`ARM_CLIENT_SECRET` — only if a `terraform plan` job is added to CI.

**Never commit secret values.** Reference them as `${{ secrets.NAME }}` only.

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
