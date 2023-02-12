# Simple Wireguard VPN server module

### This module will deploy and configure a virtual machine in Azure Public Cloud that functions as a VPN server using the Wireguard protocol. The server can be used to access specific resources within the virtual network (private endpoints for example), or can be used as an default path for internet-bound traffic from clients.

<br>

## Features

* Ephemeral VM that automatically rebuilds from scratch in the event of a failure/configuration change
* Relatively low cost for a cloud-hosted solution at ~$5/month
* Tested up to 400mbps of throughput and possibly capable of more
* Easy to deploy and tear back down for testing

<br>

## Prerequisites

1. Install Wireguard by following the instructions at [https://www.wireguard.com/install/](https://www.wireguard.com/install/)
2. Generate **unique** public/private key pairs for the server and **each** of your clients. These will need to be provided to the module in the variables [server\_public\_key](#input\_server\_public\_key), [server\_private\_key](#input\_server\_private\_key), and as part of [vpn\_clients](#input\_vpn\_clients).
    ```bash
    # generate private key
    wg genkey > example.key

    # generate public key
    wg pubkey < example.key > example.key.pub
    ```
3. Ensure that [vpn\_internal\_address\_space](#input\_vpn\_internal\_address\_space) and [virtual\_network\_address\_space](#input\_virtual\_network\_address\_space) do not overlap with any of your existing networks. The values should be RFC1918 private network addresses but otherwise can be selected at random.

<br>

## Deployment
1. Configure the azurerm provider to connect to your Azure environment. There are many ways to do this. Reference the azurerm provider docs for details at [https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs#authenticating-to-azure](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs#authenticating-to-azure)

    ```
    provider "azurerm" {
      features {}
    }
    ```
2. Add a reference to the server module to your existing module.

    **Minimal parameters (using defaults wherever possible)**
    ```
    module "wireguard_server" {
      source = "git@github.com:nkbphazon/wireguard-server.git?ref=v1.0.0"

      server_public_key  = "... your generated public key ..."
      server_private_key = "... your generated private key ..."
      vpn_clients = [
        {
          name       = "laptop"
          public_key = "... another generated public key ..."
        },
        {
          name       = "desktop"
          public_key = "... yet another generated public key ..."
        }
      ]
    }
    ```

    **All parameters**
    ```
    module "wireguard_server" {
      source = "git@github.com:nkbphazon/wireguard-server.git?ref=v1.0.0"

      server_public_key  = "... your generated public key ..."
      server_private_key = "... your generated private key ..."
      vpn_clients = [
        {
          name       = "laptop"
          public_key = "... another generated public key ..."
        },
        {
          name       = "desktop"
          public_key = "... yet another generated public key ..."
        }
      ]

      resource_group_name             = "vpn-rg"
      location                        = "East US"
      virtual_network_name            = "vpn-vnet"
      virtual_network_address_space   = "10.100.200.0/28"
      vpn_internal_address_space      = "192.168.20.0/24"
      network_security_group_name     = "vpn-nsg"
      virtual_machine_name            = "vpn-vm"
      virtual_machine_nic_name        = "vpn-vm-nic"
      virtual_machine_ip_name         = "vpn-vm-ip"
      virtual_machine_size            = "Standard_B1ls"
      virtual_machine_admin_username  = "adminuser"
      virtual_machine_admin_ssh_key   = "~/.ssh/id_rsa.pub"
      virtual_machine_image_reference = {
        publisher = "Canonical"
        offer     = "0001-com-ubuntu-server-jammy"
        sku       = "22_04-lts-gen2"
        version   = "latest"
      }
    }
    ```
3. You will probably want to output the generated client config since you need to install it on the clients. Here are a couple of options.

    **Output to local file**

    ```
    resource "local_file" "client_configs" {
      for_each = module.wireguard_server.client_configs
      content  = each.value
      filename = "client_config/${each.key}.conf"
    }
    ```

    **Output to stdout**
    ```
    output "client_configs" {
      value = module.wireguard_server.client_configs
    }
    ```

4. Apply the changes and wait for the deployment to complete.
5. Import the client configuration files on the respective clients and connect!

<br>

## Notes
### The default behavior is to only tunnel traffic that is destined to addresses on the remote Azure virtual network. To tunnel all traffic, update the AllowedIPs setting in the client configuration file to include an additional entry of 0.0.0.0/0

<br><br>

# Module details

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | 3.43.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 3.43.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_linux_virtual_machine.this](https://registry.terraform.io/providers/hashicorp/azurerm/3.43.0/docs/resources/linux_virtual_machine) | resource |
| [azurerm_network_interface.this](https://registry.terraform.io/providers/hashicorp/azurerm/3.43.0/docs/resources/network_interface) | resource |
| [azurerm_network_security_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/3.43.0/docs/resources/network_security_group) | resource |
| [azurerm_public_ip.this](https://registry.terraform.io/providers/hashicorp/azurerm/3.43.0/docs/resources/public_ip) | resource |
| [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/3.43.0/docs/resources/resource_group) | resource |
| [azurerm_subnet.this](https://registry.terraform.io/providers/hashicorp/azurerm/3.43.0/docs/resources/subnet) | resource |
| [azurerm_subnet_network_security_group_association.this](https://registry.terraform.io/providers/hashicorp/azurerm/3.43.0/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_virtual_network.this](https://registry.terraform.io/providers/hashicorp/azurerm/3.43.0/docs/resources/virtual_network) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_location"></a> [location](#input\_location) | The Azure Region where the resources should exist. | `string` | `"Central US"` | no |
| <a name="input_network_security_group_name"></a> [network\_security\_group\_name](#input\_network\_security\_group\_name) | The name of the network security group. | `string` | `"vpn-nsg"` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name which should be used for the Resource Group. | `string` | `"vpn-rg"` | no |
| <a name="input_server_private_key"></a> [server\_private\_key](#input\_server\_private\_key) | The wireguard private key to use for the server. | `string` | n/a | yes |
| <a name="input_server_public_key"></a> [server\_public\_key](#input\_server\_public\_key) | The wireguard public key to use for the server. | `string` | n/a | yes |
| <a name="input_virtual_machine_admin_ssh_key"></a> [virtual\_machine\_admin\_ssh\_key](#input\_virtual\_machine\_admin\_ssh\_key) | The admin ssh key for the virtual machine. | `string` | `"~/.ssh/id_rsa.pub"` | no |
| <a name="input_virtual_machine_admin_username"></a> [virtual\_machine\_admin\_username](#input\_virtual\_machine\_admin\_username) | The admin username for the virtual machine. | `string` | `"adminuser"` | no |
| <a name="input_virtual_machine_image_reference"></a> [virtual\_machine\_image\_reference](#input\_virtual\_machine\_image\_reference) | The image reference for the virtual machine. | <pre>object({<br>    publisher = string<br>    offer     = string<br>    sku       = string<br>    version   = string<br>  })</pre> | <pre>{<br>  "offer": "0001-com-ubuntu-server-jammy",<br>  "publisher": "Canonical",<br>  "sku": "22_04-lts-gen2",<br>  "version": "latest"<br>}</pre> | no |
| <a name="input_virtual_machine_ip_name"></a> [virtual\_machine\_ip\_name](#input\_virtual\_machine\_ip\_name) | The name of the virtual machine's public IP address. | `string` | `"vpn-vm-ip"` | no |
| <a name="input_virtual_machine_name"></a> [virtual\_machine\_name](#input\_virtual\_machine\_name) | The name of the virtual machine. | `string` | `"vpn-vm"` | no |
| <a name="input_virtual_machine_nic_name"></a> [virtual\_machine\_nic\_name](#input\_virtual\_machine\_nic\_name) | The name of the virtual machine's network interface. | `string` | `"vpn-vm-nic"` | no |
| <a name="input_virtual_machine_size"></a> [virtual\_machine\_size](#input\_virtual\_machine\_size) | The size of the virtual machine. | `string` | `"Standard_B1ls"` | no |
| <a name="input_virtual_network_address_space"></a> [virtual\_network\_address\_space](#input\_virtual\_network\_address\_space) | The address space that is used by the virtual network. | `string` | `"10.100.200.0/28"` | no |
| <a name="input_virtual_network_name"></a> [virtual\_network\_name](#input\_virtual\_network\_name) | The name of the virtual network. | `string` | `"vpn-vnet"` | no |
| <a name="input_vpn_clients"></a> [vpn\_clients](#input\_vpn\_clients) | A list of VPN clients that will connect to the server. | <pre>list(object({<br>    name       = string<br>    public_key = string<br>  }))</pre> | n/a | yes |
| <a name="input_vpn_internal_address_space"></a> [vpn\_internal\_address\_space](#input\_vpn\_internal\_address\_space) | The private address prefix to use for VPN clients. Choose a prefix that does not overlap with the existing network of the clients or the virtual network. | `string` | `"192.168.20.0/24"` | no |
| <a name="input_vpn_server_port"></a> [vpn\_server\_port](#input\_vpn\_server\_port) | The port the VPN server should listen for connections on. | `number` | `51820` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_client_configs"></a> [client\_configs](#output\_client\_configs) | The wireguard settings that should be configured on the clients. |
<!-- END_TF_DOCS -->