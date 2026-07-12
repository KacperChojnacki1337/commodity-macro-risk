# DEV environment inputs. Values are supplied via terraform.tfvars
# (copy terraform.tfvars.example -> terraform.tfvars and fill in).

variable "location" {
  description = "Azure region."
  type        = string
  default     = "westeurope"
}

variable "resource_group_name" {
  description = "Resource group name for the dev environment."
  type        = string
}

variable "storage_account_name" {
  description = "Globally-unique ADLS Gen2 account name (3-24 lowercase alphanumeric)."
  type        = string
}

variable "key_vault_name" {
  description = "Globally-unique Key Vault name."
  type        = string
}

variable "data_factory_name" {
  description = "Globally-unique Data Factory name."
  type        = string
}
