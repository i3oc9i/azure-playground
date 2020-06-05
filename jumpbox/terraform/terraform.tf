terraform {
    backend "azurerm" {
        resource_group_name  = "terraform-tfstates-rg"
        storage_account_name = "terraformtfstatesi3oc9i"
        container_name       = "tfstates"
        key                  = "jumpbox-tfstate"
    }
}
