# Infrastructure (Terraform)

Infrastructure as Code for the Azure side of the platform: **ADLS Gen2**
(raw landing zone), **Azure Key Vault** (API keys), and **Azure Data Factory**
(orchestration).

## Layout

```
infra/
  modules/            # reusable building blocks (child modules)
    adls/             # ADLS Gen2 storage account + containers
    keyvault/         # Key Vault (RBAC-authorized)
    adf/              # Data Factory with a system-assigned identity
    platform/         # composition: resource group + the three modules above
  envs/               # environments (root modules) — thin, config only
    dev/              # calls modules/platform with dev values
    prod/             # calls modules/platform with prod values
```

The real logic lives in `modules/`. Each environment is a thin root module that
calls `modules/platform` with different variable values. dev vs prod are
**separate state + separate resources**, not git branches.

## Prerequisites

- Terraform >= 1.5
- Azure CLI (`az`) for interactive auth, **or** `ARM_*` environment variables
  for CI. (Not needed for `fmt`/`validate`.)

## Cost note

Nothing here costs anything until `terraform apply`. `init`, `fmt`, and
`validate` run offline/free. Chosen defaults keep cost minimal: `Standard`/`LRS`
storage, `standard` Key Vault SKU. See [../docs/cost_model.md](../docs/cost_model.md).

## Usage (per environment)

Run everything from inside an env folder, e.g. `infra/envs/dev`.

```bash
cd infra/envs/dev

# 1) Provide values (globally-unique names!)
cp terraform.tfvars.example terraform.tfvars
#   edit terraform.tfvars

# 2) Authenticate to Azure (interactive)
az login
export ARM_SUBSCRIPTION_ID="<your-subscription-id>"

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

## State

Currently the **local** backend (`terraform.tfstate` on disk, gitignored). It
may contain sensitive values, so it is never committed. A remote `azurerm`
backend (shared, locked state) is stubbed in `providers.tf` and will be enabled
in a later milestone.
