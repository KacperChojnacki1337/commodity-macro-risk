# PROD environment inputs. Resource names are derived automatically
# (name_prefix + environment + random suffix).

variable "location" {
  description = "Azure region."
  type        = string
  default     = "westeurope"
}

variable "name_prefix" {
  description = "Short lowercase token baked into every resource name (2-8 chars)."
  type        = string
  default     = "cmdrisk"
}
