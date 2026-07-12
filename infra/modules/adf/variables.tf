# Inputs for the Azure Data Factory module.

variable "resource_group_name" {
  description = "Resource group to create the Data Factory in."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "data_factory_name" {
  description = "Globally-unique Data Factory name (3-63 chars, letters, digits and hyphens; must start and end with a letter or digit)."
  type        = string
}

variable "tags" {
  description = "Tags applied to the Data Factory."
  type        = map(string)
  default     = {}
}
