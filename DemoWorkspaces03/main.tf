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
}

#############################################################################
# VARIABLES
#############################################################################

variable "resource_group_name" {
  type = string
}

variable "location" {
  type    = string
  default = "eastus"
}


variable "vnet_cidr_range" {
  type = map(string)
  default = {
    development = "10.2.0.0/16"
    QA         = "10.3.0.0/16"
    production  = "10.4.0.0/16"
  }
}

variable "subnet_names" {
  type    = list(string)
  default = ["web", "database", "app"]
}

locals {
  full_rg_name = "${terraform.workspace}-${var.resource_group_name}"
}

#############################################################################
# PROVIDERS
#############################################################################

provider "azurerm" {
  features {}
}

#############################################################################
# RESOURCES
#############################################################################

# TEMPLATE FILES
data "template_file" "subnet_prefixes" {
  count = length(var.subnet_names)

  #define inline template 
  #function cidrsubnet - https://www.terraform.io/docs/configuration/interpolation.html#cidrsubnet-and-concat (cidrsubnet(prefix, newbits, netnum))
  template = "$${cidrsubnet(vnet_cidr,8,current_count)}"

  vars = {
    vnet_cidr     = var.vnet_cidr_range[terraform.workspace]
    current_count = count.index
  }
}

resource "azurerm_resource_group" "vnet_main" {
  name     = local.full_rg_name
  location = var.location

  tags = {
    environment = terraform.workspace
    costcenter  = "BG-UW-IT"
  }
}

module "vnet-main" {
  source              = "Azure/vnet/azurerm"
  #version             = "~> 2.0"
  resource_group_name = azurerm_resource_group.vnet_main.name
  vnet_name           = local.full_rg_name
  address_space       = [var.vnet_cidr_range[terraform.workspace]]
  subnet_prefixes     = data.template_file.subnet_prefixes[*].rendered # rendered is a list of strings from each subnet prefixes, * all elements in the list
  subnet_names        = var.subnet_names
  nsg_ids             = {}

  tags = {
    environment = terraform.workspace
    costcenter  = "BG-UW-IT"

  }

  depends_on = [azurerm_resource_group.vnet_main] #depends on the resource group to be created first before creating the vnet
}

#############################################################################
# OUTPUTS
#############################################################################

output "vnet_id" {
  value = module.vnet-main.vnet_id
}

output "vnet_name" {
  value = module.vnet-main.vnet_name
}

output "resource_group_name" {
  value = local.full_rg_name