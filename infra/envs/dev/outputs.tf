# Re-export the platform outputs for the dev environment.

output "resource_group_name" {
  value = module.platform.resource_group_name
}

output "storage_account_name" {
  value = module.platform.storage_account_name
}

output "primary_dfs_endpoint" {
  value = module.platform.primary_dfs_endpoint
}

output "raw_containers" {
  value = module.platform.raw_containers
}

output "key_vault_uri" {
  value = module.platform.key_vault_uri
}

output "data_factory_name" {
  value = module.platform.data_factory_name
}
