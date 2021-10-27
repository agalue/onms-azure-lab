# Author: Alejandro Galue <agalue@opennms.org>

resource "azurerm_network_security_group" "opennms" {
  name                = "${local.onms_vm_name}-sg"
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
    name                       = "webui"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = var.security.enabled ? "443" : "8980"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "grafana"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3000"
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

resource "azurerm_public_ip" "opennms" {
  name                = "${local.onms_vm_name}-ip"
  location            = var.location
  resource_group_name = var.resource_group.name
  tags                = local.custom_tags
  allocation_method   = "Dynamic"
  domain_name_label   = local.onms_vm_name
}

resource "azurerm_network_interface" "opennms" {
  name                = "${local.onms_vm_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group.name
  tags                = local.custom_tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    public_ip_address_id          = azurerm_public_ip.opennms.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "opennms" {
  network_interface_id      = azurerm_network_interface.opennms.id
  network_security_group_id = azurerm_network_security_group.opennms.id
}

data "template_file" "opennms" {
  template = file("opennms.yaml")

  vars = {
    user             = var.username
    location         = var.location
    email            = var.email  # Used only with LetsEncrypt
    onms_repo        = var.onms_repo
    onms_version     = var.onms_version
    heap_size        = var.heap_size.opennms
    security_enabled = var.security.enabled
    kafka_user       = var.security.kafka_user
    kafka_passwd     = var.security.kafka_passwd
    public_fqdn      = "${local.onms_vm_name}.${var.location}.cloudapp.azure.com"

    # Used only with Private Certificates generation
    ca_root_pem         = base64encode(file("./pki/ca-root.pem"))
    ca_intermediate_pem = base64encode(file("./pki/ca-intermediate.pem"))
    ca_intermediate_key = base64encode(file("./pki/ca-intermediate-key.pem"))

    # The following are defined this way to enforce the dependency against the external applications
    kafka_bootstrap = "${azurerm_linux_virtual_machine.kafka.name}:9092"
    elastic_url     = "http://${azurerm_linux_virtual_machine.elastic.name}:9200/"
  }
}

resource "azurerm_linux_virtual_machine" "opennms" {
  name                = local.onms_vm_name
  resource_group_name = var.resource_group.name
  location            = var.location
  size                = var.vm_size.opennms
  admin_username      = var.username
  admin_password      = var.password
  tags                = local.custom_tags
  custom_data         = base64encode(data.template_file.opennms.rendered)

  disable_password_authentication= false

  network_interface_ids = [
    azurerm_network_interface.opennms.id,
  ]

  source_image_reference {
    publisher = var.os_image.publisher
    offer     = var.os_image.offer
    sku       = var.os_image.sku
    version   = var.os_image.version
  }

  os_disk {
    name                 = "${local.onms_vm_name}-os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}
