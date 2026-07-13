# Providers this module needs. Declared here (no configuration) so the module
# is self-describing; the root module configures/authenticates them.

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}
