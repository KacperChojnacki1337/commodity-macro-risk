# Inputs for the platform composition module.
# One object that describes a whole environment (dev or prod).

variable "environment" {
  description = "Environment name: dev or prod. Used in tags."
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be either 'dev' or 'prod'."
  }
}

variable "location" {
  description = "Azure region for all resources (e.g. westeurope, polandcentral)."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group to create."
  type        = string
}

variable "storage_account_name" {
  description = "Globally-unique ADLS Gen2 storage account name."
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
