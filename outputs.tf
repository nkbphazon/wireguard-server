output "client_configs" {
  description = "The wireguard settings that should be configured on the clients."
  value = {
    for index, peer in var.vpn_clients : peer.name => templatefile("${path.module}/wireguard_client.tftpl", {
      server_public_key      = var.server_public_key
      client_address         = cidrhost(var.vpn_internal_address_space, 2 + index)
      server_private_address = cidrhost(var.vpn_internal_address_space, 1)
      vpn_server_host        = azurerm_public_ip.this.ip_address
      vpn_server_port        = var.vpn_server_port
      remote_network_prefix  = var.virtual_network_address_space
      client_name            = peer.name
      client_public_key      = peer.public_key
    })
  }
}
