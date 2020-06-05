provider "azurerm" {
    version = "2.2.0"
    features {}
}

resource "azurerm_resource_group" "jumpbox_rg" {
    name     = "${var.jumpbox_resource_prefix}-rg"
    location = var.jumpbox_location
}

resource "azurerm_virtual_network" "jumpbox_vnet" {
    name                = "${var.jumpbox_resource_prefix}-vnet"
    resource_group_name = azurerm_resource_group.jumpbox_rg.name
    location            = var.jumpbox_location

    address_space       = [var.jumpbox_address_space]
}

resource "azurerm_subnet" "jumpbox_subnet" {
    name                 = "${var.jumpbox_resource_prefix}-subnet"
    resource_group_name  = azurerm_resource_group.jumpbox_rg.name

    virtual_network_name = azurerm_virtual_network.jumpbox_vnet.name
    address_prefix       = var.jumpbox_address_subnet
}

resource "azurerm_public_ip" "jumpbox_public_ip" {
    name                = "${var.jumpbox_resource_prefix}-public-ip"
    resource_group_name = azurerm_resource_group.jumpbox_rg.name
    location            = var.jumpbox_location

    allocation_method   = var.jumpbox_environment == "production" ? "Static" : "Dynamic"
}

resource "azurerm_network_interface" "jumpbox_nic" {
    name                = "${var.jumpbox_name}-nic"
    resource_group_name = azurerm_resource_group.jumpbox_rg.name
    location            = var.jumpbox_location

    ip_configuration {
        name                          = "${var.jumpbox_name}-ip"
        subnet_id                     = azurerm_subnet.jumpbox_subnet.id
        private_ip_address_allocation = "dynamic"
        public_ip_address_id          = azurerm_public_ip.jumpbox_public_ip.id
    }
}

resource "azurerm_network_security_group" "jumpbox_nsg" {
    name                = "${var.jumpbox_resource_prefix}-nsg"
    resource_group_name = azurerm_resource_group.jumpbox_rg.name
    location            = var.jumpbox_location
}

resource "azurerm_network_security_rule" "jumpbox_nsg_rule_ssh" {
    resource_group_name         = azurerm_resource_group.jumpbox_rg.name
    network_security_group_name = azurerm_network_security_group.jumpbox_nsg.name

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

resource "azurerm_network_interface_security_group_association" "jumpbox_nsg_association" {
    network_security_group_id = azurerm_network_security_group.jumpbox_nsg.id
    network_interface_id      = azurerm_network_interface.jumpbox_nic.id
}

resource "azurerm_linux_virtual_machine" "jumpbox_vm" {
    name                = var.jumpbox_name
    resource_group_name = azurerm_resource_group.jumpbox_rg.name
    location            = var.jumpbox_location

    size  = "Standard_B1s"

    network_interface_ids = [
        azurerm_network_interface.jumpbox_nic.id
    ]

    admin_username = "ubuntu"
 
    admin_ssh_key {
        username   = "ubuntu"
        public_key = file(var.jumpbox_ssh_authorized_key)
    }

    os_disk {
        name                 = "${var.jumpbox_name}-os-disk"
        caching              = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }
}

