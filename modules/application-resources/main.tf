data "azurerm_client_config" "current" {}
data "azurerm_subscription" "current" {}

resource "azurerm_service_plan" "projectsp1" {
  name                = var.asp_name
  resource_group_name = var.resource_group
  location            = var.location
  sku_name            = var.sku_name
  os_type             = "Windows"
}

resource "azurerm_windows_web_app" "projectapp1" {
  name                = var.app_name
  resource_group_name = var.resource_group
  location            = var.location
  service_plan_id     = azurerm_service_plan.projectsp1.id
  site_config {
    #always_on = false
    application_stack{
    current_stack = "dotnet"
    dotnet_version = "v6.0"
  }
  }
  identity {
    type = "SystemAssigned"
  }
  tags = {
    environment = var.environment
  }
}

resource "azurerm_app_service_virtual_network_swift_connection" "projectappvnconnect1" {
  app_service_id = azurerm_windows_web_app.projectapp1.id
  subnet_id      = var.app_subnet
}

resource "azurerm_role_assignment" "projectras1" {
  principal_id = azurerm_windows_web_app.projectapp1.identity[0].principal_id
  scope = data.azurerm_subscription.current.id
  role_definition_name = var.managed_id_role
}