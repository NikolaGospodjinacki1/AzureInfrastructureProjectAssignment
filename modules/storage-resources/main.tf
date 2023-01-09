resource "azurerm_storage_account" "projectsa1" {
  name                = var.storage_account_name
  resource_group_name = var.resource_group_name

  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
  
  network_rules {
    default_action = "Allow"
    bypass = ["AzureServices"]
    virtual_network_subnet_ids = var.vnet_subnet_ids
  }
  tags = {
    environment = var.environment
  }
}
resource "azurerm_storage_container" "projectstcont1" {
  name                  = var.container_name
  storage_account_name  = azurerm_storage_account.projectsa1.name
  container_access_type = var.container_access_type
}