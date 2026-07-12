# Inputs for the Key Vault module.

variable "resource_group_name" {
  description = "Resource group to create the Key Vault in."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "key_vault_name" {
  description = "Globally-unique Key Vault name (3-24 chars, alphanumeric and hyphens, must start with a letter)."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{1,22}[a-zA-Z0-9]$", var.key_vault_name))
    error_message = "key_vault_name must be 3-24 chars, start with a letter, and contain only letters, digits and hyphens."
  }
}

variable "tenant_id" {
  description = "Azure AD tenant ID that owns the Key Vault (read from azurerm_client_config)."
  type        = string
}

variable "tags" {
  description = "Tags applied to the Key Vault."
  type        = map(string)
  default     = {}
}
