# Create a virtual network within the resource group
resource "azurerm_virtual_network" "projectvnet1" {
  name                = var.virtual_network_name
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = [var.vnet_address_space]
}

resource "azurerm_subnet" "subnets" {
  for_each             = var.subnets
  depends_on           = [azurerm_virtual_network.projectvnet1]
  name                 = each.key
  resource_group_name  = azurerm_virtual_network.projectvnet1.resource_group_name
  virtual_network_name = azurerm_virtual_network.projectvnet1.name
  address_prefixes     = each.value.cidr
  service_endpoints    = ["Microsoft.Sql", "Microsoft.KeyVault", "Microsoft.Web", "Microsoft.Storage"]
  dynamic "delegation" {
    for_each = each.value.service_delegation == true ? [1] : []

    content {
        name = "delegation"

        service_delegation {
        name = "Microsoft.Web/serverFarms"
        actions = [
          "Microsoft.Network/virtualNetworks/subnets/action",
          "Microsoft.Network/virtualNetworks/subnets/join/action",
        ]
      }
    }
  }
}

/* resource "azurerm_subnet" "app-service-fe-vnet" {
  name                 = "snet-project-${var.env}-${random_string.suffix.result}-appservice1-vnet"
  resource_group_name  = azurerm_resource_group.groups["networking"].name
  virtual_network_name = azurerm_virtual_network.projectvnet1.name
  address_prefixes     = [var.subnet_ranges[0]]
  service_endpoints    = [ "Microsoft.Web" ]
  delegation {
    name = "delegation"

    service_delegation {
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action",
        "Microsoft.Network/virtualNetworks/subnets/join/action"
      ]
      name = "Microsoft.Web/serverFarms"
    }
  }
} */