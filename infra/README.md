# Infrastructure (Terraform)

Infrastructure as Code for the Azure side of the platform: **ADLS Gen2**
(raw landing zone), **Azure Key Vault** (API keys), and **Azure Data Factory**
(orchestration).

## Layout

```
infra/
  modules/            # reusable building blocks (child modules) — never applied directly
    adls/             # ADLS Gen2 storage account + containers
    keyvault/         # Key Vault (RBAC-authorized)
    adf/              # Data Factory with a system-assigned identity
    platform/         # composition: resource group + the three modules above
  envs/               # ROOT modules, per environment
    dev/              # calls modules/platform with dev values
    prod/             # calls modules/platform with prod values
  subscription/       # ROOT module, account-wide resources (monthly budget)
```

**Root modules are split by scope**, each with its own state and lifecycle:

| Root | Manages | Apply when |
|------|---------|------------|
| `envs/dev` | the dev environment (RG, ADLS, Key Vault, ADF) | working on dev; `destroy` between sessions |
| `envs/prod` | the prod environment | promoting to prod |
| `subscription` | the whole Azure account (budget/cost guard) | once; independent of environments |

That separation is deliberate: routinely running `terraform destroy` on `envs/dev`
must not remove the account-wide cost guard. The real logic lives in `modules/`;
roots are thin and config-only. dev vs prod are **separate state + separate
resources**, not git branches.

## Prerequisites

- Terraform >= 1.5
- Azure CLI (`az`) for interactive auth, **or** `ARM_*` environment variables
  for CI. (Not needed for `fmt`/`validate`.)

## Cost note

Nothing here costs anything until `terraform apply`. `init`, `fmt`, and
`validate` run offline/free. Chosen defaults keep cost minimal: `Standard`/`LRS`
storage, `standard` Key Vault SKU. See [../docs/cost_model.md](../docs/cost_model.md).

## Naming (trial-portable)

Resource names are **derived automatically** as
`<prefix>-<environment>-<random-suffix>` (see `modules/platform`). You never
type a globally-unique name. The random suffix is stored in state, so it is
stable across applies on the same trial, but regenerates on a fresh state — so
moving to a new Azure trial produces new unique names with **zero code edits**.

Only two things are ever environment/trial-specific, and neither lives in git:
the Azure login (`az login`) and `ARM_SUBSCRIPTION_ID`.

## Usage (per environment)

Run everything from inside an env folder, e.g. `infra/envs/dev`.

```bash
cd infra/envs/dev

# 1) Authenticate to Azure (interactive) and select the subscription
az login
export ARM_SUBSCRIPTION_ID="<your-subscription-id>"

# 2) (optional) override defaults — NOT required; defaults just work
# cp terraform.tfvars.example terraform.tfvars

# 3) Standard workflow
terraform init        # download providers, prepare the working dir
terraform fmt         # format the code
terraform validate    # check config is valid (offline)
terraform plan        # dry-run: show what WOULD change (needs Azure auth)
terraform apply       # create the resources (needs Azure auth) -> COSTS start
```

## Teardown (destroy everything)

Bring standing cost back to zero when you are not working:

```bash
cd infra/envs/dev
terraform destroy     # removes all resources in this environment
# repeat in infra/envs/prod if it was applied
```

Because everything is code, a fresh environment can be rebuilt from scratch with
`terraform apply` (important: both Azure and Snowflake run on time-limited trial
credit).

## Switching Azure trials

When the current trial nears expiry, migrating to a fresh one is deliberately
cheap:

**Before the old trial expires**

```bash
cd infra/envs/dev && terraform destroy   # release resources cleanly
```

**On the new trial**

```bash
az login                                  # log into the NEW account
export ARM_SUBSCRIPTION_ID="<new-sub-id>"

cd infra/envs/dev
rm -rf .terraform terraform.tfstate*      # drop old local state (old sub)
terraform init
terraform apply                           # new unique names generated automatically
```

No code or `tfvars` changes are needed: names are regenerated, and the
subscription is supplied purely via `az login` + `ARM_SUBSCRIPTION_ID`. This is
why the whole platform must stay reproducible from code (see the project
charter, §10).

## State

Currently the **local** backend (`terraform.tfstate` on disk, gitignored). It
may contain sensitive values, so it is never committed. A remote `azurerm`
backend (shared, locked state) is stubbed in `providers.tf` and will be enabled
in a later milestone.
