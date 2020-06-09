#-- The Jumpbox config
#--
variable "jumpbox_environment" {
    type = string
    default = "production"
}

variable "jumpbox_resource_prefix" {
    type = string
    default = "jumpbox"
}

variable "jumpbox_name" {
    type = string
    default = "jumpbox-vm"
}

variable "jumpbox_count" {
    type = number
    default = 2
}

variable "jumpbox_location" {
    type = string
    default = "westus2"
}

variable "jumpbox_ssh_authorized_key" {
    type = string
    default = "~/.ssh/id_rsa.pub"
}

variable "jumpbox_vnet_address_space" {
    type = string
    default = "10.0.0.0/16"
}

variable "jumpbox_subnets_addresses" {
    type = map(string)

    default = {
        jumpbox_subnet     = "1.0.1.0/24"
        AzureBastionSubnet = "1.0.2.0/24"
    }
}

variable "remote_authorized_ips" {
    type = list(string)
    default = ["0.0.0.0"]
}

