# ADLS Gen2 = a StorageV2 account with the hierarchical namespace enabled.
# This is the RAW landing zone: ADF writes here, Snowflake reads via a stage.

resource "azurerm_storage_account" "this" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS" # locally redundant = cheapest; fine for a portfolio
  account_kind             = "StorageV2"
  is_hns_enabled           = true # hierarchical namespace -> this makes it ADLS Gen2
  min_tls_version          = "TLS1_2"

  tags = var.tags
}

# One container per name (default: "raw"). Private access only.
resource "azurerm_storage_container" "this" {
  for_each = toset(var.container_names)

  name                  = each.value
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"
}
