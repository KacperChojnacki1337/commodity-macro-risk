# Values this module exposes to its caller.

output "data_factory_id" {
  description = "Resource ID of the Data Factory."
  value       = azurerm_data_factory.this.id
}

output "data_factory_name" {
  description = "Name of the Data Factory."
  value       = azurerm_data_factory.this.name
}

output "identity_principal_id" {
  description = "Object ID of the ADF managed identity — used to grant it access to ADLS and Key Vault."
  value       = azurerm_data_factory.this.identity[0].principal_id
}
