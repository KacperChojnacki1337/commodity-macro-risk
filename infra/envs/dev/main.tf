# DEV root module: just calls the shared platform module with dev values.
# All the real resource logic lives in modules/platform.

module "platform" {
  source = "../../modules/platform"

  environment          = "dev"
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_name = var.storage_account_name
  key_vault_name       = var.key_vault_name
  data_factory_name    = var.data_factory_name
}
