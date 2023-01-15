data "azurerm_client_config" "current" {}
data "azurerm_subscription" "current" {}

resource "azurerm_key_vault" "projectkv1" {
  name                        = var.vault_name
  location                    = var.location
  resource_group_name         = var.resource_group_name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"
  network_acls {
    bypass                     = "AzureServices"
    default_action             = "Deny"
    ip_rules                   = var.ip_rules #Home IP allow
    virtual_network_subnet_ids = var.virtual_network_subnet_ids
  }
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get", "Delete", "List", "Backup", "Restore", "Recover", "Rotate"
    ]

    secret_permissions = [
      "Get", "Set", "Delete", "List", "Backup", "Purge", "Restore", "Recover",
    ]

    storage_permissions = [
      "Get",
    ]

    certificate_permissions = [
      "Get",
    ]
  }
  tags = {
    "environment" = var.environment
  }
}

resource "azurerm_private_endpoint" "main" {
  name                = "${azurerm_key_vault.projectkv1.name}-pe"
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.virtual_network_subnet_ids[0]
  private_dns_zone_group {
    name                 = "devtest"
    private_dns_zone_ids = var.private_dns_zone_ids
  }
  private_service_connection {
    is_manual_connection           = false
    private_connection_resource_id = azurerm_key_vault.projectkv1.id
    name                           = "${azurerm_key_vault.projectkv1.name}-psc"
    subresource_names              = ["vault"]
  }
  depends_on = [azurerm_key_vault.projectkv1]
}

# # Create KeyVault Secret
resource "azurerm_key_vault_secret" "projectsqlusername1" {
  name         = var.sql_username_secret_name
  value        = var.sql_username_secret_value
  key_vault_id = azurerm_key_vault.projectkv1.id
  tags = {
    "environent" = var.environment
  }
}

resource "azurerm_key_vault_secret" "projectsqlpassword1" {
  name         = var.sql_password_secret_name
  value        = var.sql_password_secret_value
  key_vault_id = azurerm_key_vault.projectkv1.id
  tags = {
    "environent" = var.environment
  }
}