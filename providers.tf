terraform {
  required_version = ">=0.12"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.74.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }

    azapi = {
      source  = "azure/azapi"
      version = "~>1.0"
    }

    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  subscription_id = "edda3b24-4311-437d-8084-ac3b3bb67cfc"
  features {}
}

provider "azapi" {
}