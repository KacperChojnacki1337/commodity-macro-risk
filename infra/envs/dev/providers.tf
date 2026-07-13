# Terraform + provider setup for the DEV environment (root module).

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  # State backend.
  # For now we use the default LOCAL backend (terraform.tfstate on disk),
  # which is enough for a skeleton and needs no Azure auth.
  #
  # Later (M2+) we switch to a remote azurerm backend so state is shared and
  # locked. Uncomment and fill in once a state storage account exists:
  #
  # backend "azurerm" {
  #   resource_group_name  = "rg-tfstate"
  #   storage_account_name = "sttfstatecommodity"
  #   container_name       = "tfstate"
  #   key                  = "dev.terraform.tfstate"
  # }
}

provider "azurerm" {
  features {}

  # Authentication is provided at plan/apply time, NOT hard-coded here:
  #   - `az login` (interactive), or
  #   - ARM_SUBSCRIPTION_ID / ARM_TENANT_ID / ARM_CLIENT_ID / ARM_CLIENT_SECRET
  #     environment variables (used by CI).
}
