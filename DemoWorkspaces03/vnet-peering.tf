variable "sec_sub_id" {
  type = string
}

variable "sec_client_id" {
  type = string
}

variable "sec_client_secret" {
  type = string
}

variable "sec_tenant_id" {
  type = string
}

variable "sec_vnet_name" {
  type = string
}

variable "sec_vnet_id" {
  type = string
}

variable "sec_resource_group" {
  type = string
}

variable "sec_principal_id" {
  type = string
}


data "azurerm_subscription" "current" {} # Get the current subscription ID, current subscription defined in the provider block. if provider is not defined, it will take the default subscription


provider "azurerm" {
  alias                       = "security"
  subscription_id             = var.sec_sub_id
  client_id                   = var.sec_client_id
  client_secret               = var.sec_client_secret
  tenant_id                   = var.sec_tenant_id
  skip_provider_registration  = true
  skip_credentials_validation = true
  features {}
}

provider "azurerm" {
  alias                       = "peering"
  subscription_id             = data.azurerm_subscription.current.subscription_id
  client_id                   = var.sec_client_id
  client_secret               = var.sec_client_secret
  tenant_id                   = data.azurerm_subscription.current.tenant_id
  skip_provider_registration  = true
  skip_credentials_validation = true
  features {}
}

# Create a custom role definition to allow the peering action. This role will be assigned to the peering service principal.
resource "azurerm_role_definition" "vnet-peering" {
  # The name of the role definition. Role for each workspace. This name must be unique within the RoleDefinition namespace.
  name  = "allow-vnet-peer-action-${terraform.workspace}"
  scope = data.azurerm_subscription.current.id

  permissions {
    actions     = ["Microsoft.Network/virtualNetworks/virtualNetworkPeerings/write", "Microsoft.Network/virtualNetworks/peer/action", "Microsoft.Network/virtualNetworks/virtualNetworkPeerings/read", "Microsoft.Network/virtualNetworks/virtualNetworkPeerings/delete"]
    not_actions = []
  }

  assignable_scopes = [
    data.azurerm_subscription.current.id,
  ]

  # output for debugging with a current subscription ID
  output "role_definition_resource_id" {
    value = azurerm_role_definition.vnet-peering.role_definition_resource_id 
    color = "red"
  }

}

resource "azurerm_role_assignment" "vnet" {
  scope              = module.vnet-main.vnet_id
  role_definition_id = azurerm_role_definition.vnet-peering.role_definition_resource_id
  principal_id       = var.sec_principal_id
}

resource "azurerm_virtual_network_peering" "main" {
  name                      = "${terraform.workspace}_2_sec"
  resource_group_name       = azurerm_resource_group.vnet_main.name
  virtual_network_name      = module.vnet-main.vnet_name
  remote_virtual_network_id = var.sec_vnet_id
  provider                  = azurerm.peering

  depends_on = [azurerm_role_assignment.vnet]
}

resource "azurerm_virtual_network_peering" "sec" {
  name                      = "sec_2_${terraform.workspace}"
  resource_group_name       = var.sec_resource_group
  virtual_network_name      = var.sec_vnet_name
  remote_virtual_network_id = module.vnet-main.vnet_id
  provider                  = azurerm.security

  depends_on = [azurerm_role_assignment.vnet]
}