data "azurerm_client_config" "current" {}
data "azurerm_subscription" "current" {}

resource "azurerm_mssql_server" "projectsqlsrv1" {
  name                         = var.server_name
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = "12.0"
  minimum_tls_version          = "1.2"
  administrator_login          = var.administrator_login
  administrator_login_password = var.administrator_login_password
  #public_network_access_enabled = false

  azuread_administrator {
    login_username = var.AD_admin_login_username
    object_id      = data.azurerm_client_config.current.object_id
  }
  identity {
    type = "SystemAssigned"
  }
  tags = {
    environment = var.environment
  }
}

resource "azurerm_mssql_virtual_network_rule" "projectsqlvnrule" {
  name       = var.vnet_rule_name
  server_id  = azurerm_mssql_server.projectsqlsrv1.id
  subnet_id  = var.vnet_rule_subnet_id
  depends_on = [var.vnet_rule_subnet_id]
}

resource "azurerm_mssql_database" "projectsqldb1" {
  name         = var.db_name
  server_id    = azurerm_mssql_server.projectsqlsrv1.id
  collation    = "SQL_Latin1_General_CP1_CI_AS"
  license_type = "LicenseIncluded"
  max_size_gb  = 2
  sku_name     = var.sku_name
  tags = {
    "environent" = var.environment
  }
}

resource "azurerm_role_assignment" "projectras3" {
  principal_id         = azurerm_mssql_server.projectsqlsrv1.identity[0].principal_id
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
}

resource "azurerm_mssql_firewall_rule" "projectfr1" {
  name             = "Allow access to db from home"
  server_id        = azurerm_mssql_server.projectsqlsrv1.id
  start_ip_address = "188.2.186.19"
  end_ip_address   = "188.2.186.19"
}