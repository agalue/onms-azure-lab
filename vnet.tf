# Author: Alejandro Galue <agalue@opennms.org>

resource "azurerm_resource_group" "main" {
  count    = var.resource_group.create ? 1 : 0
  name     = var.resource_group.name
  location = var.location
  tags     = local.custom_tags
}

resource "azurerm_virtual_network" "main" {
  name                = local.vnet_name
  location            = var.location
  resource_group_name = var.resource_group.name
  address_space       = [var.address_space]
  tags                = local.custom_tags
}

resource "azurerm_subnet" "main" {
  name                 = "main"
  resource_group_name  = var.resource_group.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet]
}