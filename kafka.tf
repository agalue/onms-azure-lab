# Author: Alejandro Galue <agalue@opennms.org>

resource "azurerm_network_security_group" "kafka" {
  name                = "${local.kafka_vm_name}-sg"
  location            = var.location
  resource_group_name = var.resource_group.name
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
    name                       = "client" # For external Minions
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9094"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "cmak" # Kafka Manager
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "http" # For LetsEncrypt
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_public_ip" "kafka" {
  name                = "${local.kafka_vm_name}-ip"
  location            = var.location
  resource_group_name = var.resource_group.name
  tags                = local.custom_tags
  allocation_method   = "Dynamic"
  domain_name_label   = local.kafka_vm_name
}

resource "azurerm_network_interface" "kafka" {
  name                = "${local.kafka_vm_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group.name
  tags                = local.custom_tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    public_ip_address_id          = azurerm_public_ip.kafka.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "kafka" {
  network_interface_id      = azurerm_network_interface.kafka.id
  network_security_group_id = azurerm_network_security_group.kafka.id
}

data "template_file" "kafka" {
  template = file("kafka.yaml")

  vars = {
    user             = var.username
    location         = var.location
    email            = var.email
    public_fqdn      = "${local.kafka_vm_name}.${var.location}.cloudapp.azure.com"
    security_enabled = var.security.enabled
    jks_passwd       = var.security.jks_passwd
    cmak_user        = var.security.cmak_user
    cmak_passwd      = var.security.cmak_passwd
    zk_heap_size     = var.heap_size.zookeeper
    zk_user          = var.security.zk_user
    zk_passwd        = var.security.zk_passwd
    kafka_user       = var.security.kafka_user
    kafka_passwd     = var.security.kafka_passwd
    kafka_heap_size  = var.heap_size.kafka
    kafka_partitions = 8
  }
}

resource "azurerm_linux_virtual_machine" "kafka" {
  name                = local.kafka_vm_name
  resource_group_name = var.resource_group.name
  location            = var.location
  size                = var.vm_size.kafka
  admin_username      = var.username
  admin_password      = var.password
  tags                = local.custom_tags
  custom_data         = base64encode(data.template_file.kafka.rendered)

  disable_password_authentication= false

  network_interface_ids = [
    azurerm_network_interface.kafka.id,
  ]

  source_image_reference {
    publisher = var.os_image.publisher
    offer     = var.os_image.offer
    sku       = var.os_image.sku
    version   = var.os_image.version
  }

  os_disk {
    name                 = "${local.kafka_vm_name}-os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}
