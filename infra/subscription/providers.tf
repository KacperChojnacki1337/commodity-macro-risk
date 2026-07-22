# Terraform + provider setup for the SUBSCRIPTION-scoped root module.

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  # Local backend for now (see envs/dev/providers.tf for the remote plan).
}

provider "azurerm" {
  features {}

  # Auth via `az login` or ARM_* environment variables.
}
