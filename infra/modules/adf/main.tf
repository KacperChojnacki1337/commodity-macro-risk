# Azure Data Factory — the orchestrator that runs the metadata-driven
# ingestion pipeline (Lookup sources.json -> ForEach -> Copy to ADLS).
#
# A SystemAssigned managed identity gives ADF its own Azure AD identity, so we
# can grant it access to ADLS and Key Vault via role assignments later
# (no secrets/connection strings needed for those).

resource "azurerm_data_factory" "this" {
  name                = var.data_factory_name
  resource_group_name = var.resource_group_name
  location            = var.location

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}
