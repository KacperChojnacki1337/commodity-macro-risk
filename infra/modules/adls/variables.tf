# Inputs for the ADLS Gen2 module.

variable "resource_group_name" {
  description = "Name of the resource group to create the storage account in."
  type        = string
}

variable "location" {
  description = "Azure region (e.g. westeurope, polandcentral)."
  type        = string
}

variable "storage_account_name" {
  description = "Globally-unique storage account name (3-24 chars, lowercase letters and digits only)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "storage_account_name must be 3-24 lowercase alphanumeric characters."
  }
}

variable "container_names" {
  description = "Blob containers to create (the raw landing zone lives here)."
  type        = list(string)
  default     = ["raw"]
}

variable "tags" {
  description = "Tags applied to all resources in this module."
  type        = map(string)
  default     = {}
}
