#-- The webserver config
#--
variable "webserver_environment" {
    type = string
    default = "production"
}

variable "webserver_resource_prefix" {
    type = string
    default = "webserver"
}

variable "webserver_name" {
    type = string
    default = "webserver-vm"
}

variable "webserver_count" {
    type = number
    default = 2
}

variable "webserver_location" {
    type = string
    default = "westus2"
}

variable "webserver_ssh_authorized_key" {
    type = string
    default = "~/.ssh/id_rsa.pub"
}

variable "webserver_vnet_address_space" {
    type = string
    default = "10.0.0.0/16"
}

variable "webserver_subnets_addresses" {
    type = map(string)

    default = {
        webserver_subnet   = "1.0.1.0/24"
        AzureBastionSubnet = "1.0.2.0/24"
    }
}

variable "remote_authorized_ips" {
    type = list(string)
    default = ["0.0.0.0"]
}

