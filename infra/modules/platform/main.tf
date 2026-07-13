# Platform composition: resource group + ADLS + Key Vault + ADF.
# Environments (envs/dev, envs/prod) call this single module.

# Read-only lookup of the caller's Azure context (we need the tenant_id for Key Vault).
data "azurerm_client_config" "current" {}

# Random suffix -> globally-unique names. It is stored in state, so it stays
# stable across applies on the SAME trial, but regenerates on a fresh state
# (i.e. when you move to a new Azure trial), giving new unique names for free.
resource "random_string" "suffix" {
  length  = 5
  lower   = true
  upper   = false
  numeric = true
  special = false
}

locals {
  suffix = random_string.suffix.result

  # Resource group is unique per-subscription only (no global uniqueness needed).
  resource_group_name = "rg-${var.name_prefix}-${var.environment}"

  # Storage account: 3-24 chars, lowercase letters + digits only (no hyphens).
  storage_account_name = "st${var.name_prefix}${var.environment}${local.suffix}"

  # Key Vault: 3-24 chars, start with a letter, letters/digits/hyphens.
  key_vault_name = "kv-${var.name_prefix}-${var.environment}-${local.suffix}"

  # Data Factory: 3-63 chars, letters/digits/hyphens.
  data_factory_name = "adf-${var.name_prefix}-${var.environment}-${local.suffix}"

  # Consistent tags on every resource — makes cost tracking and teardown easy.
  tags = {
    project     = "commodity-macro-risk"
    environment = var.environment
    managed_by  = "terraform"
  }
}

resource "azurerm_resource_group" "this" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.tags
}

module "adls" {
  source = "../adls"

  resource_group_name  = azurerm_resource_group.this.name
  location             = azurerm_resource_group.this.location
  storage_account_name = local.storage_account_name
  container_names      = ["raw"]
  tags                 = local.tags
}

module "keyvault" {
  source = "../keyvault"

  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  key_vault_name      = local.key_vault_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  tags                = local.tags
}

module "adf" {
  source = "../adf"

  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  data_factory_name   = local.data_factory_name
  tags                = local.tags
}
