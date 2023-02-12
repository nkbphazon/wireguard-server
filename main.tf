terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.43.0"
    }
  }
}

resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "this" {
  name                = var.virtual_network_name
  address_space       = [var.virtual_network_address_space]
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_subnet" "this" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.virtual_network_address_space]
}

resource "azurerm_network_interface" "this" {
  name                = var.virtual_machine_nic_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  enable_ip_forwarding = true

  ip_configuration {
    name                          = "default"
    subnet_id                     = azurerm_subnet.this.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.this.id
  }
}

resource "azurerm_subnet_network_security_group_association" "this" {
  subnet_id                 = azurerm_subnet.this.id
  network_security_group_id = azurerm_network_security_group.this.id
}

resource "azurerm_network_security_group" "this" {
  name                = var.network_security_group_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  security_rule {
    name                       = "AllowWireguardInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = var.vpn_server_port
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "DefaultDenyInbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

}

resource "azurerm_public_ip" "this" {
  name                = var.virtual_machine_ip_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  allocation_method   = "Static"
  sku                 = "Basic"
}

resource "azurerm_linux_virtual_machine" "this" {
  name                = var.virtual_machine_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  size                = var.virtual_machine_size
  admin_username      = var.virtual_machine_admin_username
  network_interface_ids = [
    azurerm_network_interface.this.id,
  ]
  custom_data = base64encode(templatefile("${path.module}/cloud-init.tftpl", {
    wireguard_config = indent(8, templatefile("${path.module}/wireguard_server.tftpl", {
      server_private_address = cidrhost(var.vpn_internal_address_space, 1)
      server_private_key     = var.server_private_key
      vpn_server_port        = var.vpn_server_port
      vpn_clients = [for index, peer in var.vpn_clients : {
        public_key = peer.public_key
        ip_address = cidrhost(var.vpn_internal_address_space, 2 + index)
        name       = peer.name
      }]
    }))
  }))

  admin_ssh_key {
    username   = var.virtual_machine_admin_username
    public_key = file(var.virtual_machine_admin_ssh_key)
  }

  os_disk {
    caching              = "ReadOnly"
    disk_size_gb         = 30
    storage_account_type = "Standard_LRS"

    diff_disk_settings {
      option    = "Local"
      placement = "CacheDisk"
    }
  }

  source_image_reference {
    publisher = var.virtual_machine_image_reference.publisher
    offer     = var.virtual_machine_image_reference.offer
    sku       = var.virtual_machine_image_reference.sku
    version   = var.virtual_machine_image_reference.version
  }

}
