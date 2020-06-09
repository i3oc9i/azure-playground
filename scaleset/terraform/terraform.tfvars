
webserver_environment = "development"

webserver_count = 2

webserver_location = "francecentral"

webserver_vnet_address_space  = "10.3.0.0/16"

webserver_subnets_addresses = {
    webserver_subnet     = "10.3.1.0/24"
    AzureBastionSubnet = "10.3.2.0/24"
}

webserver_ssh_authorized_key = "~/.ssh/azure_key.pub"


# remote_authorized_ips = ["<set the remote ip>"]