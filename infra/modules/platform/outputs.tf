# Bubble up the useful values from the child modules.

output "resource_group_name" {
  description = "Name of the resource group."
  value       = azurerm_resource_group.this.name
}

output "storage_account_name" {
  description = "ADLS Gen2 storage account name."
  value       = module.adls.storage_account_name
}

output "primary_dfs_endpoint" {
  description = "ADLS dfs endpoint (for the Snowflake external stage)."
  value       = module.adls.primary_dfs_endpoint
}

output "raw_containers" {
  description = "Containers created in the storage account."
  value       = module.adls.container_names
}

output "key_vault_uri" {
  description = "Key Vault URI."
  value       = module.keyvault.key_vault_uri
}

output "data_factory_name" {
  description = "Data Factory name."
  value       = module.adf.data_factory_name
}

output "adf_identity_principal_id" {
  description = "ADF managed identity object ID (grant it ADLS/Key Vault access later)."
  value       = module.adf.identity_principal_id
}
