provider "azurerm" {
  subscription_id = "df762d06-9685-438e-aed0-d55b807198a7"
  client_id       = "fe40b964-81a6-42f6-8f0e-e205c8c9a4b9"
  client_secret   = "cZFkJ83-hOsPGWLxlTLTELG37U2hhKvc-H"
  tenant_id       = "b7540979-5063-4ba1-a9a0-49b436141ffb"
  features {}
}

resource "azurerm_resource_group" "setup" {
  name     = local.az_resource_group_name
  location = var.az_location
}

resource "azurerm_storage_account" "sa" {
  name                     = local.az_storage_account_name
  resource_group_name      = azurerm_resource_group.setup.name
  location                 = var.az_location
  account_tier             = "Standard"
  account_replication_type = "LRS"

}

resource "azurerm_storage_container" "ct" {
  name                 = "terraform-state"
  storage_account_name = azurerm_storage_account.sa.name

}

data "azurerm_storage_account_sas" "state" {
  connection_string = azurerm_storage_account.sa.primary_connection_string
  https_only        = true

  resource_types {
    service   = true
    container = true
    object    = true
  }

  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }

  start  = timestamp()
  expiry = timeadd(timestamp(), "17520h")

  permissions {
    read    = true
    write   = true
    delete  = true
    list    = true
    add     = true
    create  = true
    update  = false
    process = false
  }
}