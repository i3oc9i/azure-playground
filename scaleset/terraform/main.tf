provider "azurerm" {
    version = "2.2.0"
    features {}
}

locals {
    web_server_name   = var.environment == "production" ? "${var.web_server_name}-prd" : "${var.web_server_name}-dev"
    build_environment = var.environment == "production" ? "production" : "development"
}

resource "azurerm_resource_group" "webserver_rg" {
    name     = "${var.webserver_resource_prefix}-rg"
    location = var.webserver_location
}

resource "azurerm_virtual_network" "webserver_vnet" {
    name                = "${var.webserver_resource_prefix}-vnet"
    resource_group_name = azurerm_resource_group.webserver_rg.name
    location            = var.webserver_location

    address_space       = [var.webserver_vnet_address_space]
}

resource "azurerm_subnet" "webserver_subnet" {
    for_each = var.webserver_subnets_addresses
    
        name                 = each.key
        resource_group_name  = azurerm_resource_group.webserver_rg.name
        virtual_network_name = azurerm_virtual_network.webserver_vnet.name
        address_prefix       = each.value
}

resource "azurerm_public_ip" "webserver_public_ip" {
    name                = "${var.webserver_resource_prefix}-public-ip"
    resource_group_name = azurerm_resource_group.webserver_rg.name
    location            = var.webserver_location

    allocation_method   = var.webserver_environment == "production" ? "Static" : "Dynamic"
}

resource "azurerm_network_security_group" "webserver_nsg" {
    name                = "${var.webserver_resource_prefix}-nsg"
    resource_group_name = azurerm_resource_group.webserver_rg.name
    location            = var.webserver_location
}

resource "azurerm_network_security_rule" "webserver_nsg_rule_ssh" {
    resource_group_name         = azurerm_resource_group.webserver_rg.name
    network_security_group_name = azurerm_network_security_group.webserver_nsg.name

    count = var.webserver_environment == "production" ? 0 : 1 # in production we disallow SSH

    name                        = "SSH Inbound"
    priority                    = 100
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "Tcp"
    source_address_prefixes     = var.remote_authorized_ips
    source_port_range           = "*"
    destination_address_prefix  = "*"
    destination_port_range      = "22"
}

resource "azurerm_subnet_network_security_group_association" "webserver_sag" {
    network_security_group_id = azurerm_network_security_group.webserver_nsg.id
    subnet_id                 = azurerm_subnet.webserver_subnet["webserver_subnet"].id
}

resource "azurerm_virtual_machine_scale_set" "webserver_vm" {
    name                = "${var.webserver_resource_prefix}-scale-set"
    resource_group_name = azurerm_resource_group.webserver_rg.name
    location            = var.webserver_location

    upgrade_policy_mode = "manual"

    network_profile {
        name    = "${var.webserver_resource_prefix}-network-profile"
        primary = true

        ip_configuration {
            name      = var.webserver_name
            primary   = true
            subnet_id = azurerm_subnet.webserver_subnet["webserver_subnet"].id
        }
    }

    sku {
        name     = "Standard_B1s"
        tier     = "Standard"
        capacity = var.webserver_count
    }

    storage_profile_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

    storage_profile_os_disk {
        name              = ""
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Standard_LRS"
    }

    os_profile {
        computer_name_prefix = var.webserver_name

        admin_username = "ubuntu"
    }

    os_profile_linux_config {
        disable_password_authentication = true

        ssh_keys {
            key_data = file(var.webserver_ssh_authorized_key)
            path     = "/home/ubuntu/.ssh/authorized_keys"
        }
    }

    tags = {
        environment = var.webserver_resource_prefix
    }
}

