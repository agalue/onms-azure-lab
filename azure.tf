# Author: Alejandro Galue <agalue@opennms.org>

# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

provider "azurerm" {
  skip_provider_registration = true
  features {}
}
