# Key Vault stores API keys (EIA, GUS, ...). sources.json references secrets
# by NAME only; the values live here and are fetched at runtime.
#
# We use RBAC authorization (enable_rbac_authorization = true) rather than the
# older access-policy model: access is granted via Azure role assignments,
# which is the current recommended approach.

resource "azurerm_key_vault" "this" {
  name                = var.key_vault_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tenant_id           = var.tenant_id
  sku_name            = "standard"

  rbac_authorization_enabled = true

  # Portfolio/trial: keep teardown easy. In a real prod setup you would enable
  # purge protection so secrets cannot be permanently deleted by accident.
  purge_protection_enabled   = false
  soft_delete_retention_days = 7

  tags = var.tags
}
