variable "resource_group_name" {
  type        = string
  description = "The name which should be used for the Resource Group."
  default     = "vpn-rg"
}

variable "location" {
  type        = string
  description = "The Azure Region where the resources should exist."
  default     = "Central US"
}

variable "virtual_network_name" {
  type        = string
  description = "The name of the virtual network."
  default     = "vpn-vnet"
}

variable "virtual_network_address_space" {
  type        = string
  description = "The address space that is used by the virtual network."
  default     = "10.100.200.0/28"
}

variable "vpn_internal_address_space" {
  type        = string
  description = "The private address prefix to use for VPN clients. Choose a prefix that does not overlap with the existing network of the clients or the virtual network."
  default     = "192.168.20.0/24"
}

variable "network_security_group_name" {
  type        = string
  description = "The name of the network security group."
  default     = "vpn-nsg"
}

variable "virtual_machine_name" {
  type        = string
  description = "The name of the virtual machine."
  default     = "vpn-vm"
}

variable "virtual_machine_nic_name" {
  type        = string
  description = "The name of the virtual machine's network interface."
  default     = "vpn-vm-nic"
}

variable "virtual_machine_ip_name" {
  type        = string
  description = "The name of the virtual machine's public IP address."
  default     = "vpn-vm-ip"
}

variable "virtual_machine_size" {
  type        = string
  description = "The size of the virtual machine."
  default     = "Standard_B1ls"
}

variable "virtual_machine_admin_username" {
  type        = string
  description = "The admin username for the virtual machine."
  default     = "adminuser"
}

variable "virtual_machine_admin_ssh_key" {
  type        = string
  description = "The admin ssh key for the virtual machine."
  default     = "~/.ssh/id_rsa.pub"
}

variable "virtual_machine_image_reference" {
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  description = "The image reference for the virtual machine."
  default = {
    publisher = "canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "minimal"
    version   = "latest"
  }
}

variable "vpn_clients" {
  type = list(object({
    name       = string
    public_key = string
  }))
  description = "A list of VPN clients that will connect to the server."
}

variable "server_public_key" {
  type        = string
  description = "The wireguard public key to use for the server."
}

variable "server_private_key" {
  type        = string
  sensitive   = true
  description = "The wireguard private key to use for the server."
}

variable "vpn_server_port" {
  type        = number
  default     = 51820
  description = "The port the VPN server should listen for connections on."
}
