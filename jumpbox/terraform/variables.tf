#-- The Jumpbox config
#--
variable "jumpbox_environment" {
    type = string
    default = "development"
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

variable "jumpbox_address_space" {
    type = string
    default = "10.0.0.0/16"
}

variable "jumpbox_address_subnet" {
    type = string
    default = "1.0.1.0/24"
}

variable "jumpbox_ssh_authorized_key" {
    type = string
    default = "~/.ssh/id_rsa.pub"
}

variable "remote_authorized_ips" {
    type = list(string)
    default = ["0.0.0.0"]
}

