###########################
# CONFIGURATION
###########################

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.0"

    }
  }

  backend "azurerm" {
    
  }
}

###########################
# VARIABLES
###########################

variable "region" {
  type        = string
  description = "Region in Azure"
  default     = "westeurope"
}

variable "prefix" {
  type        = string
  description = "prefix for naming"
  default     = "tacos"
}

###########################
# PROVIDERS
###########################

provider "azurerm" {
  subscription_id = "df762d06-9685-438e-aed0-d55b807198a7"
  client_id       = "fe40b964-81a6-42f6-8f0e-e205c8c9a4b9"
  client_secret   = "cZFkJ83-hOsPGWLxlTLTELG37U2hhKvc-H"
  tenant_id       = "b7540979-5063-4ba1-a9a0-49b436141ffb"
  
  features {}
}

###########################
# DATA SOURCES
###########################

locals {
  name = "${var.prefix}-${random_id.seed.hex}"
}

###########################
# RESOURCES
###########################

resource "random_id" "seed" {
  byte_length = 4
}

resource "azurerm_resource_group" "vnet" {
  name     = local.name
  location = var.region
}

module "network" {
  source              = "Azure/network/azurerm"
  version             = "3.1.1"
  resource_group_name = azurerm_resource_group.vnet.name
  vnet_name           = local.name
  address_space       = "10.0.0.0/16"
  subnet_prefixes     = ["10.0.0.0/24","10.0.2.0/24","10.0.4.0/24"]
  subnet_names        = ["subnet1", "subnet2", "subnet4"]
  // subnet_prefixes     = ["10.0.0.0/24","10.0.2.0/24","10.0.4.0/24"]
  // subnet_names        = ["subnet1", "subnet2","subnet4"]

  depends_on = [azurerm_resource_group.vnet]
}