#############################################################################
# TERRAFORM CONFIG
#############################################################################

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.0"
    }
  }
  backend "azurerm" {
    resource_group_name   = "terraform-rg"
    storage_account_name  = "terraformstorageuw"
    container_name        = "terraform-container"
    key                   = "vnetDemo1.terraform.tfstate"
  }
}

#############################################################################
# VARIABLES
#############################################################################

variable "resource_group_name" {
  default     = "teraform-rg"
  type = string
}

variable "Subscription_ID" {
  default     = "25ed9b92-f207-49e9-ae71-1005a8cfc30e"
  type = string
}

variable "resource_name_prefix" {
  default     = "trdemo"
  description = "Prefix of the resources"
}

variable "location" {
  type    = string
  default = "eastus"
}


variable "vnet_cidr_range" {
  type    = string
  default = "10.0.0.0/16"
}

variable "subnet_prefixes" {
  type    = list(string)
  default = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
}

variable "subnet_names" {
  type    = list(string)
  default = ["web", "database", "app"]
}

#############################################################################
# PROVIDERS
#############################################################################

provider "azurerm" {
  features {}
  subscription_id = var.Subscription_ID
  use_msi = true
}

#############################################################################
# RESOURCES
#############################################################################

resource "azurerm_resource_group" "vnet_main" {
  name     = var.resource_group_name
  location = var.location
}

module "vnet-main" {
  source              = "Azure/vnet/azurerm"
  version             = "~> 2.0"
  resource_group_name = azurerm_resource_group.vnet_main.name
  vnet_name           = var.resource_group_name
  address_space       = [var.vnet_cidr_range]
  subnet_prefixes     = var.subnet_prefixes
  subnet_names        = var.subnet_names
  nsg_ids             = {}

  tags = {
    environment = "dev"
    costcenter  = "UWIT-MI"

  }

  depends_on = [azurerm_resource_group.vnet_main]
}

#############################################################################
# OUTPUTS
#############################################################################

output "vnet_id" {
  value = module.vnet-main.vnet_id
}

