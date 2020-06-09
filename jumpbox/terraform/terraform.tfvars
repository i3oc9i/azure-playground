
jumpbox_environment = "development"

jumpbox_count = 2

jumpbox_location = "francecentral"

jumpbox_vnet_address_space  = "10.3.0.0/16"

jumpbox_subnets_addresses = {
    jumpbox_subnet     = "10.3.1.0/24"
    AzureBastionSubnet = "10.3.2.0/24"
}

jumpbox_ssh_authorized_key = "~/.ssh/azure_key.pub"


# remote_authorized_ips = ["<set the remote ip>"]