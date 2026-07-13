# PROD environment inputs. Resource names are derived automatically
# (name_prefix + environment + random suffix).

variable "location" {
  description = "Azure region. Poland Central: accepts trial customers and fits the PL domain (West Europe often rejects new trials)."
  type        = string
  default     = "polandcentral"
}

variable "name_prefix" {
  description = "Short lowercase token baked into every resource name (2-8 chars)."
  type        = string
  default     = "cmdrisk"
}
