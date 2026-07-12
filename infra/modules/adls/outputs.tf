# Values this module exposes to its caller (the platform module).

output "storage_account_id" {
  description = "Resource ID of the storage account."
  value       = azurerm_storage_account.this.id
}

output "storage_account_name" {
  description = "Name of the storage account."
  value       = azurerm_storage_account.this.name
}

output "primary_dfs_endpoint" {
  description = "Primary Data Lake (dfs) endpoint — used when configuring the Snowflake external stage."
  value       = azurerm_storage_account.this.primary_dfs_endpoint
}

output "container_names" {
  description = "Names of the created containers."
  value       = [for c in azurerm_storage_container.this : c.name]
}
