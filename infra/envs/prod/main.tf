# PROD root module: calls the shared platform module with prod values.

module "platform" {
  source = "../../modules/platform"

  environment          = "prod"
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_name = var.storage_account_name
  key_vault_name       = var.key_vault_name
  data_factory_name    = var.data_factory_name
}
