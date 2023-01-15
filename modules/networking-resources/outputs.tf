output "virtual_network_name" {
  value = azurerm_virtual_network.projectvnet1.name
}

output "virtual_network_id" {
  value = azurerm_virtual_network.projectvnet1.id
}

output "snet-project-appservice-fe-vnet-id" {
  value = azurerm_subnet.subnets["snet-project-appservice-fe-vnet"].id
}

output "snet-project-appservice2-be-vnet-id" {
  value = azurerm_subnet.subnets["snet-project-appservice2-be-vnet"].id
}

output "snet-project-appservice1-fe-privendp-id" {
  value = azurerm_subnet.subnets["snet-project-appservice1-fe-privendp"].id
}

output "snet-project-appservice2-be-privendp-id" {
  value = azurerm_subnet.subnets["snet-project-appservice2-be-privendp"].id
}

output "snet-project-appservice2-be-privendp-ip-range" {
  value = azurerm_subnet.subnets["snet-project-appservice2-be-privendp"].address_prefixes
}


output "snet-project-redis-id" {
  value = azurerm_subnet.subnets["snet-project-redis"].id
}

output "snet-project-redis-ip-range" {
  value = azurerm_subnet.subnets["snet-project-redis"].address_prefixes
}

output "snet-project-sqlserver-id" {
  value = azurerm_subnet.subnets["snet-project-sqlserver"].id
}

output "snet-project-vault-id" {
  value = azurerm_subnet.subnets["snet-project-vault"].id
}

