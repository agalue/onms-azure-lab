# Author: Alejandro Galue <agalue@opennms.org>

variable "username" {
  description = "Username to access the VMs and uniquely identify all Azure resources"
  type        = string
}

variable "password" {
  description = "Password to access the VMs for the chosen user"
  type        = string
}

variable "location" {
  description = "Azure Location/Region"
  type        = string
  default     = "eastus"
}

variable "resource_group_create" {
  description = "Set to true to create the resource group (false to reuse an existing one)"
  type        = bool
  default     = false
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "support-testing"
}

# Must be consistent with the chosen Location/Region
variable "os_image" {
  description = "OS Image to use for all Applications"
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "8_3"
    version   = "latest"
  }
}

# Used only when resource_group_create=true
variable "address_space" {
  description = "Virtual Network Address Space"
  type        = string
  default     = "10.0.0.0/16"
}

# Must exist within the address_space of the chosen virtual network
variable "subnet" {
  description = "Main Subnet Range"
  type        = string
  default     = "10.0.2.0/24"
}

# Must be consistent with the chosen Location/Region
variable "vm_size" {
  description = "OS Image to use for all Applications"
  type = object({
    opennms       = string
    kafka         = string
    elasticsearch = string
  })
  default = {
    opennms       = "Standard_DS4_v2"
    kafka         = "Standard_DS4_v2"
    elasticsearch = "Standard_DS4_v2"
  }
}

variable "heap_size" {
  description = "Java Heap Memory Size all Applications expressed in MB"
  type = object({
    opennms       = string
    zookeeper     = string
    kafka         = string
    elasticsearch = string
  })
  default = {
    opennms       = "4096"
    zookeeper     = "2048"
    kafka         = "2048"
    elasticsearch = "4096"
  }
}

locals {
  custom_tags    = {
    Environment  = "Test"
    Department   = "Support"
    Owner        = var.username
  }
  onms_vm_name = "${var.username}-onms"
  kafka_vm_name = "${var.username}-kafka"
  elastic_vm_name = "${var.username}-elastic"
}
