# Inputs for the platform composition module.
#
# Resource names are NOT passed in. They are derived from name_prefix +
# environment + a random suffix, so a fresh apply on a new Azure trial always
# gets globally-unique names with zero code/tfvars edits.

variable "environment" {
  description = "Environment name: dev or prod. Used in names and tags."
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

variable "name_prefix" {
  description = "Short lowercase token baked into every resource name (2-8 chars, letters/digits)."
  type        = string
  default     = "cmdrisk"

  validation {
    condition     = can(regex("^[a-z0-9]{2,8}$", var.name_prefix))
    error_message = "name_prefix must be 2-8 lowercase alphanumeric characters."
  }
}
