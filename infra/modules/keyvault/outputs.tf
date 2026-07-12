# Values this module exposes to its caller.

output "key_vault_id" {
  description = "Resource ID of the Key Vault."
  value       = azurerm_key_vault.this.id
}

output "key_vault_uri" {
  description = "Vault URI (used by ADF/Snowflake to fetch secrets at runtime)."
  value       = azurerm_key_vault.this.vault_uri
}
