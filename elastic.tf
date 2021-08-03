# Author: Alejandro Galue <agalue@opennms.org>

resource "azurerm_network_security_group" "elastic" {
  name                = "${local.elastic_vm_name}-sg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = local.custom_tags

  security_rule {
    name                       = "ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "kibana"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5601"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_public_ip" "elastic" {
  name                = "${local.elastic_vm_name}-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = local.custom_tags
  allocation_method   = "Dynamic"
  domain_name_label   = local.elastic_vm_name
}

resource "azurerm_network_interface" "elastic" {
  name                = "${local.elastic_vm_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = local.custom_tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    public_ip_address_id          = azurerm_public_ip.elastic.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "elastic" {
  network_interface_id      = azurerm_network_interface.elastic.id
  network_security_group_id = azurerm_network_security_group.elastic.id
}

data "template_file" "elastic" {
  template = file("elastic.yaml")

  vars = {
    user      = var.username
    location  = var.location
    version   = "7.6.2"
    heap_size = var.heap_size.elasticsearch
  }
}

resource "azurerm_linux_virtual_machine" "elastic" {
  name                = local.elastic_vm_name
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.vm_size.elasticsearch
  admin_username      = var.username
  admin_password      = var.password
  tags                = local.custom_tags
  custom_data         = base64encode(data.template_file.elastic.rendered)

  disable_password_authentication= false

  network_interface_ids = [
    azurerm_network_interface.elastic.id,
  ]

  source_image_reference {
    publisher = var.os_image.publisher
    offer     = var.os_image.offer
    sku       = var.os_image.sku
    version   = var.os_image.version
  }

  os_disk {
    name                 = "${local.elastic_vm_name}-os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}
