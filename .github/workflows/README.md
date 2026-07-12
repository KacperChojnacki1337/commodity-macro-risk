# CI/CD workflows

GitHub Actions that guard `main`. Each `.yml` here is an independent workflow.

## Workflows

| File | Trigger | What it does | Needs secrets? |
|------|---------|--------------|----------------|
| `ci.yml` | every PR to `main` + push to `main` | `validate-sources` (sources.json valid + required shape) and `terraform` (fmt-check + validate for dev & prod) | no |
| `dbt-ci.yml` | PR/push touching `dbt/**` (+ manual) | Builds the dbt project against the **dev** target. No-op until `dbt/dbt_project.yml` exists. | yes (Snowflake) |

`ci.yml` needs no cloud access — Terraform `validate` and JSON checks run
offline — so it stays green from day one and is the natural **required status
check** for merging into `main`.

## Secrets (set in repo Settings → Secrets and variables → Actions)

None are required yet. They are added as later milestones need them:

| Secret | Used by | Milestone |
|--------|---------|-----------|
| `SNOWFLAKE_ACCOUNT` | dbt-ci | M1 (when dbt project lands) |
| `SNOWFLAKE_USER` | dbt-ci | M1 |
| `SNOWFLAKE_PASSWORD` | dbt-ci | M1 |
| `SNOWFLAKE_ROLE` | dbt-ci | M1 |
| `SNOWFLAKE_WAREHOUSE` | dbt-ci | M1 |
| `SNOWFLAKE_DATABASE` | dbt-ci | M1 |
| `ARM_SUBSCRIPTION_ID` / `ARM_TENANT_ID` / `ARM_CLIENT_ID` / `ARM_CLIENT_SECRET` | future `terraform plan` job | M1 (#5, provisioning) |

**Never commit secret values.** Reference them as `${{ secrets.NAME }}` only.
