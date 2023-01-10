terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.38.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "=3.4.3"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}
data "azurerm_subscription" "current" {}
/* data "azuread_user" "current" {}
data "azuread_client_config" "current" {} */

module "naming" {
  source                 = "Azure/naming/azurerm"
  version                = "0.2.0"
  suffix                 = ["dev"]
  unique-include-numbers = true
}

# Generate random value for the name
resource "random_string" "projectsqlrand1" {
  length  = 8
  lower   = true
  numeric = false
  special = false
  upper   = false
}

resource "random_string" "suffix" {
  length  = 4
  lower   = true
  numeric = true
  special = false
  upper   = false
}

# Generate random value for the login password
resource "random_password" "projectsqlrand2" {
  length           = 16
  lower            = true
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  min_upper        = 1
  numeric          = true
  override_special = "_"
  special          = true
  upper            = true
}

# Create a resource group
resource "azurerm_resource_group" "projectrg1" {
  name     = "rg-project-${var.env}-${random_string.suffix.result}main"
  location = var.region
}

resource "azurerm_resource_group" "database" {
  name     = "rg-project-${var.env}-${random_string.suffix.result}database"
  location = var.region
}

resource "azurerm_resource_group" "redis" {
  name     = "rg-project-${var.env}-${random_string.suffix.result}redis"
  location = var.region
}

resource "azuread_group" "projectadgroup1" {
  display_name     = "Agency-AAD-Admins"
  security_enabled = true
}

resource "azurerm_role_assignment" "projectras-main" {
  scope                = azurerm_resource_group.projectrg1.id
  role_definition_name = "Contributor"
  principal_id         = azuread_group.projectadgroup1.object_id
}

resource "azurerm_role_assignment" "projectras-database" {
  scope                = azurerm_resource_group.database.id
  role_definition_name = "Contributor"
  principal_id         = azuread_group.projectadgroup1.object_id
}

resource "azurerm_role_assignment" "projectras-redis" {
  scope                = azurerm_resource_group.redis.id
  role_definition_name = "Contributor"
  principal_id         = azuread_group.projectadgroup1.object_id
}

module "vault-resources" {
  source              = "./modules/vault-resources"
  vault_name          = "kv-project-${var.env}-${random_string.suffix.result}"
  location            = var.region
  resource_group_name = azurerm_resource_group.projectrg1.name
  sku_name            = "standard"
  virtual_network_subnet_ids = [azurerm_subnet.sqlapi.id,
    azurerm_subnet.projectprivsub2.id,
    azurerm_subnet.frontend.id,
  azurerm_subnet.storagepriv.id]
  sql_username_secret_name  = "kv-secret--${var.env}-sqluname-${random_string.suffix.result}"
  sql_username_secret_value = random_string.projectsqlrand1.result
  sql_password_secret_name  = "kv-secret--${var.env}-sqlpwd-${random_string.suffix.result}"
  sql_password_secret_value = random_password.projectsqlrand2.result
  environment               = var.env
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "projectvnet1" {
  name                = "vnet-project-${var.env}-${random_string.suffix.result}1"
  resource_group_name = azurerm_resource_group.projectrg1.name
  location            = azurerm_resource_group.projectrg1.location
  address_space       = [var.vnet_range]
  tags = {
    "environent" = var.env
  }
}

resource "azurerm_subnet" "frontend" {
  name                 = "snet-project-${var.env}-${random_string.suffix.result}-frontend"
  resource_group_name  = azurerm_resource_group.projectrg1.name
  virtual_network_name = azurerm_virtual_network.projectvnet1.name
  address_prefixes     = [var.subnet_ranges[0]]
  service_endpoints    = ["Microsoft.Storage", "Microsoft.Web", "Microsoft.KeyVault"]
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
}

resource "azurerm_subnet" "storagepriv" {
  name                 = "snet-project-${var.env}-${random_string.suffix.result}-storagepriv"
  resource_group_name  = azurerm_resource_group.projectrg1.name
  virtual_network_name = azurerm_virtual_network.projectvnet1.name
  address_prefixes     = [var.subnet_ranges[1]]
  service_endpoints    = ["Microsoft.Storage", "Microsoft.Web", "Microsoft.KeyVault"]
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
}

resource "azurerm_subnet" "sqlapi" {
  name                 = "snet-project-${var.env}-${random_string.suffix.result}-sqlapi"
  resource_group_name  = azurerm_resource_group.projectrg1.name
  virtual_network_name = azurerm_virtual_network.projectvnet1.name
  address_prefixes     = [var.subnet_ranges[2]]
  service_endpoints    = ["Microsoft.Storage", "Microsoft.Sql", "Microsoft.KeyVault"]
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
}

resource "azurerm_subnet" "projectprivsub2" {
  name                 = "snet-project-${var.env}-${random_string.suffix.result}-priv2"
  resource_group_name  = azurerm_resource_group.projectrg1.name
  virtual_network_name = azurerm_virtual_network.projectvnet1.name
  address_prefixes     = [var.subnet_ranges[3]]
  service_endpoints    = ["Microsoft.Storage", "Microsoft.Sql", "Microsoft.KeyVault"]
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
}

resource "azurerm_network_security_group" "frontendsg" {
  name                = "nsg-project-${var.env}-${random_string.suffix.result}1"
  location            = azurerm_resource_group.projectrg1.location
  resource_group_name = azurerm_resource_group.projectrg1.name

  security_rule {
    name                       = "Allow-all-frontend"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "443"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  tags = {
    subnet = "frontend"
  }
}

/* resource "azurerm_network_security_group" "backendsg" {
  name                = "nsg-project-${var.env}-${random_string.suffix.result}1"
  location            = azurerm_resource_group.projectrg1.location
  resource_group_name = azurerm_resource_group.projectrg1.name

  security_rule {
    name                       = "Deny-all-backend"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  tags = {
    subnet = "backend"
  }
} */

/* resource "azurerm_subnet_network_security_group_association" "projectsgassocfe" {
  subnet_id                 = azurerm_subnet.sqlapi.id
  network_security_group_id = azurerm_network_security_group.backendsg.id
} */

resource "azurerm_subnet_network_security_group_association" "projectsgassocbe" {
  subnet_id                 = azurerm_subnet.frontend.id
  network_security_group_id = azurerm_network_security_group.frontendsg.id
}

module "database-resources" {
  source                       = "./modules/database-resources"
  server_name                  = "sql-project-${var.env}-${random_string.suffix.result}"
  resource_group_name          = azurerm_resource_group.database.name
  location                     = var.region
  administrator_login          = module.vault-resources.sql_username_secret_value
  administrator_login_password = module.vault-resources.sql_password_secret_value
  AD_admin_login_username      = "AzureAD Admin"
  vnet_rule_name               = "vnet-rule-project-${var.env}-${random_string.suffix.result}"
  vnet_rule_subnet_id          = azurerm_subnet.sqlapi.id
  db_name                      = "sqldb-project-${var.env}-${random_string.suffix.result}"
  max_size_gb                  = var.max_db_size
  sku_name                     = var.db_sku
  environment                  = var.env
}
module "application-resources-fe" {
  source          = "./modules/application-resources"
  asp_name        = "asp-project-${var.env}-${random_string.suffix.result}1fe"
  resource_group  = azurerm_resource_group.projectrg1.name
  location        = azurerm_resource_group.projectrg1.location
  sku_name        = "B1"
  app_name        = "app-project-${var.env}-${random_string.suffix.result}1fe"
  app_subnet      = azurerm_subnet.frontend.id
  managed_id_role = "Contributor"
  environment     = var.env
}

module "application-resources-be" {
  source          = "./modules/application-resources"
  asp_name        = "asp-project-${var.env}-${random_string.suffix.result}2be"
  resource_group  = azurerm_resource_group.projectrg1.name
  location        = azurerm_resource_group.projectrg1.location
  sku_name        = "B1"
  app_name        = "app-project-${var.env}-${random_string.suffix.result}2be"
  app_subnet      = azurerm_subnet.sqlapi.id
  managed_id_role = "Contributor"
  environment     = var.env
}

module "storage_resources_API" {
  source                   = "./modules/storage-resources"
  storage_account_name     = "stproject${var.env}${random_string.suffix.result}api"
  resource_group_name      = azurerm_resource_group.projectrg1.name
  location                 = var.region
  account_tier             = "Standard"
  account_replication_type = "LRS"
  vnet_subnet_ids          = [azurerm_subnet.storagepriv.id]
  environment              = var.env
  container_name           = "stapi"
  container_access_type    = "private"
}

/* module "storage_resources_TFSTATE" {
  source                   = "./modules/storage-resources"
  storage_account_name     = "stproject${var.env}${random_string.suffix.result}tfstate"
  resource_group_name      = azurerm_resource_group.projectrg1.name
  location                 = var.region
  account_tier             = "Standard"
  account_replication_type = "LRS"
  vnet_subnet_ids          = [azurerm_subnet.storagepriv.id]
  environment              = var.env
  container_name           = "sttfstate"
  container_access_type    = "private"
} */

module "redis-resources" {
  source                             = "./modules/redis-resources"
  name                               = "redis-project-${var.env}-${random_string.suffix.result}1"
  location                           = var.region
  resource_group_name                = azurerm_resource_group.redis.name
  capacity                           = 0
  family                             = "C"
  sku_name                           = "Basic"
  environment                        = var.env
  dns_zone_name                      = "project.privatelink.redis.cache.windows.net"
  dns_zone_virtual_network_link_name = "project-redis"
  virtual_network_id                 = azurerm_virtual_network.projectvnet1.id
}



#### OLD snippets to be deleted once everything's done ####

/* resource "azurerm_role_assignment" "projectras4" {
  principal_id = azurerm_redis_cache.projectredis1.id
  scope = data.azurerm_subscription.current.id
  role_definition_id = "${data.azurerm_subscription.current.id}${data.azurerm_role_definition.contributor.id}"
} */


/* 
esource "azurerm_mssql_server" "projectsqlsrv1" {
  name                         = module.naming.mssql_server.name_unique
  resource_group_name          = azurerm_resource_group.projectrg1.name
  location                     = azurerm_resource_group.projectrg1.location
  version                      = "12.0"
  minimum_tls_version          = "1.2"
  administrator_login          = azurerm_key_vault_secret.projectsqlusername1.value
  administrator_login_password = azurerm_key_vault_secret.projectsqlpassword1.value
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "projectras3" {
  principal_id = azurerm_mssql_server.projectsqlsrv1.identity[0].principal_id
  scope = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
}

resource "azurerm_mssql_virtual_network_rule" "projectsqlvnrule" {
  name      = module.naming.network_security_rule.name_unique
  server_id = azurerm_mssql_server.projectsqlsrv1.id
  subnet_id = azurerm_subnet.projectprivsub1.id
  depends_on = [ azurerm_subnet.projectprivsub1]
}

resource "azurerm_mssql_database" "projectsqldb1" {
  name           = module.naming.mssql_database.name_unique
  server_id      = azurerm_mssql_server.projectsqlsrv1.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = 2
  sku_name       = "Basic"

  tags = {
    env = "dev"
  }
} */


/* resource "azurerm_key_vault" "projectkv1" {
  name                        = module.naming.key_vault.name_unique
  location                    = azurerm_resource_group.projectrg1.location
  resource_group_name         = azurerm_resource_group.projectrg1.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  
  sku_name = "standard"
  network_acls {
    bypass = "AzureServices"
    default_action = "Deny"
    ip_rules = [ "188.2.186.19" ] #Home IP allow
    virtual_network_subnet_ids =  [ azurerm_subnet.projectprivsub1.id, 
                                    azurerm_subnet.projectprivsub2.id,
                                    azurerm_subnet.projectpubsub1.id,
                                    azurerm_subnet.projectpubsub2.id ]
  }
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get", "Set", "Delete", "List", "Backup", "Purge", "Restore", "Recover",
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
}

# # Create KeyVault Secret
resource "azurerm_key_vault_secret" "projectsqlusername1" {
  name         = module.naming.key_vault_secret.name_unique
  value        = random_string.projectsqlrand1.result
  key_vault_id = azurerm_key_vault.projectkv1.id
  depends_on = [azurerm_key_vault.projectkv1]
}

resource "azurerm_key_vault_secret" "projectsqlpassword1" {
  name         = module.naming.key_vault_secret.name_unique
  value        = random_password.projectsqlrand2.result
  key_vault_id = azurerm_key_vault.projectkv1.id
  depends_on = [azurerm_key_vault.projectkv1]
} */

/* resource "azurerm_service_plan" "projectsp1" {
  name                = module.naming.app_service_plan.name_unique
  resource_group_name = azurerm_resource_group.projectrg1.name
  location            = azurerm_resource_group.projectrg1.location
  sku_name            = "B1"
  os_type             = "Windows"
}

resource "azurerm_windows_web_app" "projectapp1" {
  name                = "app-dev-1111"
  resource_group_name = azurerm_resource_group.projectrg1.name
  location            = azurerm_service_plan.projectsp1.location
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
}

resource "azurerm_app_service_virtual_network_swift_connection" "projectappvnconnect1" {
  app_service_id = azurerm_windows_web_app.projectapp1.id
  subnet_id      = azurerm_subnet.projectpubsub1.id
}


resource "azurerm_role_assignment" "projectras1" {
  principal_id = azurerm_windows_web_app.projectapp1.identity[0].principal_id
  scope = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
}

resource "azurerm_windows_web_app" "projectapp2" {
  name                = "app-dev-2222"
  resource_group_name = azurerm_resource_group.projectrg1.name
  location            = azurerm_service_plan.projectsp1.location
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
}

resource "azurerm_app_service_virtual_network_swift_connection" "projectappvnconnect2" {
  app_service_id = azurerm_windows_web_app.projectapp2.id
  subnet_id      = azurerm_subnet.projectprivsub1.id
}

resource "azurerm_role_assignment" "projectras2" {
  principal_id = azurerm_windows_web_app.projectapp2.identity[0].principal_id
  scope = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
} */

/* resource "azurerm_api_management" "projectapiman1" {
  name                = "example-apim"
  location            = azurerm_resource_group.projectrg1.location
  resource_group_name = azurerm_resource_group.projectrg1.name
  publisher_name      = "Assignment Project"
  publisher_email     = "ngogank@gmail.com"
  
  virtual_network_type = "External"
  virtual_network_configuration {
    subnet_id = azurerm_subnet.projectpubsub2.id
  }
  sku_name = "Basic_1"
}

resource "azurerm_api_management_api" "projectapi1" {
  name                = module.naming.api_management.name_unique
  resource_group_name = azurerm_resource_group.projectrg1.name
  api_management_name = azurerm_api_management.projectapiman1.name
  revision            = "1"
  display_name        = "Project API"
  path                = "example"
  protocols           = ["https"]

  import {
    content_format = "swagger-link-json"
    content_value  = "http://conferenceapi.azurewebsites.net/?format=json"
  }
} */

/* resource "azurerm_redis_cache" "projectredis1" {
  name                = "redis-project-${var.env}-${random_string.suffix.result}1"
  location            = var.region
  resource_group_name = azurerm_resource_group.redis.name
  capacity            = 0
  family              = "C"
  sku_name            = "Basic"
  enable_non_ssl_port = false
  public_network_access_enabled = false
  tags = {
    environment = var.env
  }
}

resource "azurerm_private_dns_zone" "redis" {
  name = "project.privatelink.redis.cache.windows.net"
  resource_group_name = azurerm_resource_group.redis.name
  tags = {
    environment = var.env
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "redis" {
  name = "project-redis"
  private_dns_zone_name = azurerm_private_dns_zone.redis.name
  virtual_network_id = azurerm_virtual_network.projectvnet1.id
  resource_group_name = azurerm_resource_group.redis.name
} */

/* resource "azurerm_storage_account" "projectsa1" {
  name                = "stproject${var.env}${random_string.suffix.result}1"
  resource_group_name = azurerm_resource_group.projectrg1.name

  location                 = azurerm_resource_group.projectrg1.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  network_rules {
    default_action = "Allow"
    bypass = ["AzureServices"]
    virtual_network_subnet_ids = [azurerm_subnet.projectpubsub2.id]
  }
  tags = {
    environment = var.env
  }
}

resource "azurerm_storage_container" "example" {
  name                  = "vhds"
  storage_account_name  = azurerm_storage_account.projectsa1.name
  container_access_type = "private"
}

resource "azurerm_storage_account" "projectsa2" {
  name                = "stproject${var.env}${random_string.suffix.result}2"
  resource_group_name = azurerm_resource_group.projectrg1.name
  location                 = azurerm_resource_group.projectrg1.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  network_rules {
    default_action = "Allow"
    bypass = ["AzureServices"]
    virtual_network_subnet_ids = [azurerm_subnet.projectpubsub2.id]
  }
  tags = {
    environment = var.env
  }
} */