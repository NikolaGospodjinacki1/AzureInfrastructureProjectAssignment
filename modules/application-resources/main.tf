data "azurerm_client_config" "current" {}
data "azurerm_subscription" "current" {}

resource "azurerm_service_plan" "projectsp1" {
  name                = var.asp_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku_name            = var.sku_name
  os_type             = "Windows"
}

resource "azurerm_windows_web_app" "projectapp1" {
  name                = var.app_name
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.projectsp1.id
  site_config {
    #always_on = false
    application_stack {
      current_stack  = "dotnet"
      dotnet_version = "v6.0"
    }
  }
  identity {
    type = "SystemAssigned"
  }
  app_settings = {
    APPINSIGHTS_INSTRUMENTATIONKEY = var.instrumentation_key
  }
  tags = {
    environment = var.environment
  }
}

resource "azurerm_role_assignment" "projectras1" {
  principal_id         = azurerm_windows_web_app.projectapp1.identity[0].principal_id
  scope                = data.azurerm_subscription.current.id
  role_definition_name = var.managed_id_role
}

resource "azurerm_app_service_virtual_network_swift_connection" "projectappvnconnect1" {
  app_service_id = azurerm_windows_web_app.projectapp1.id
  subnet_id      = var.app_subnet_id
}

resource "azurerm_private_endpoint" "app_pe" {
  name                = var.endpoint_name
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.endpoint_subnet_id

  private_service_connection {
    name                           = var.priv_svc_connection_name
    private_connection_resource_id = azurerm_windows_web_app.projectapp1.id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = var.private_dns_zone_name
    private_dns_zone_ids = var.private_dns_zone_ids
  }
}




