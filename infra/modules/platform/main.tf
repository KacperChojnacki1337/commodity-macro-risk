# Platform composition: resource group + ADLS + Key Vault + ADF.
# Environments (envs/dev, envs/prod) call this single module.

# Read-only lookup of the caller's Azure context (we need the tenant_id for Key Vault).
data "azurerm_client_config" "current" {}

locals {
  # Consistent tags on every resource — makes cost tracking and teardown easy.
  tags = {
    project     = "commodity-macro-risk"
    environment = var.environment
    managed_by  = "terraform"
  }
}

resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.tags
}

module "adls" {
  source = "../adls"

  resource_group_name  = azurerm_resource_group.this.name
  location             = azurerm_resource_group.this.location
  storage_account_name = var.storage_account_name
  container_names      = ["raw"]
  tags                 = local.tags
}

module "keyvault" {
  source = "../keyvault"

  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  key_vault_name      = var.key_vault_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  tags                = local.tags
}

module "adf" {
  source = "../adf"

  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  data_factory_name   = var.data_factory_name
  tags                = local.tags
}
