provider "azurerm" {
    version = "2.2.0"
    features {}
}

locals {
    webserver_name    = var.webserver_environment == "production" ? "${var.webserver_name}-prd" : "${var.webserver_name}-dev"
    build_environment = var.webserver_environment == "production" ? "production" : "development"
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

resource "azurerm_public_ip" "webserver_lb_public_ip" {
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

resource "azurerm_network_security_rule" "webserver_nsg_rule_http" {
    resource_group_name         = azurerm_resource_group.webserver_rg.name
    network_security_group_name = azurerm_network_security_group.webserver_nsg.name

    count = var.webserver_environment == "production" ? 0 : 1 # in production we disallow SSH

    name                        = "HTTP Inbound"
    priority                    = 110
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "Tcp"
    source_address_prefixes     = var.remote_authorized_ips
    source_port_range           = "*"
    destination_address_prefix  = "*"
    destination_port_range      = "80"
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
            name                                   = local.webserver_name
            primary                                = true
            subnet_id                              = azurerm_subnet.webserver_subnet["webserver_subnet"].id
            load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.webserver_lb_backend_pool.id]
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
        computer_name_prefix = local.webserver_name

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
        application   = local.webserver_name
        build         = local.build_environment
        build-version = var.webserver_version
    }
}

resource "azurerm_lb" "webserver_lb" {
    name                = "${var.webserver_resource_prefix}-lb"
    resource_group_name = azurerm_resource_group.webserver_rg.name
    location            = var.webserver_location

    frontend_ip_configuration {
        name                 = "${var.webserver_resource_prefix}-lb-frontend-ip"
        public_ip_address_id = azurerm_public_ip.webserver_lb_public_ip.id
    }
}

resource "azurerm_lb_backend_address_pool" "webserver_lb_backend_pool" {
    name                = "${var.webserver_resource_prefix}-lb-backend-pool"
    resource_group_name = azurerm_resource_group.webserver_rg.name

    loadbalancer_id = azurerm_lb.webserver_lb.id
}

resource "azurerm_lb_probe" "webserver_lb_http_probe" {
    name                = "${var.webserver_resource_prefix}-lb-http-probe"
    resource_group_name = azurerm_resource_group.webserver_rg.name

    loadbalancer_id = azurerm_lb.webserver_lb.id

    protocol = "tcp"
    port     = "80"
}

resource "azurerm_lb_rule" "webserver_lb_http_rule" {
    name                = "${var.webserver_resource_prefix}-lb-http-rule"
    resource_group_name = azurerm_resource_group.webserver_rg.name

    loadbalancer_id = azurerm_lb.webserver_lb.id

    frontend_ip_configuration_name = "${var.webserver_resource_prefix}-lb-frontend-ip"

    protocol = "tcp"

    frontend_port = "80"
    backend_port  = "80"

    probe_id = azurerm_lb_probe.webserver_lb_http_probe.id

    backend_address_pool_id = azurerm_lb_backend_address_pool.webserver_lb_backend_pool.id
}

