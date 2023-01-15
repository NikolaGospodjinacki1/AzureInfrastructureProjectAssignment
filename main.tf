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
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  client_id = var.spn-client_id
  client_secret = var.spn-client-secret
  tenant_id = var.spn-tenant-id
}

data "azurerm_client_config" "current" {}
data "azurerm_subscription" "current" {}

resource "azurerm_private_dns_zone" "private_dns_zones" {
  for_each            = var.private_dns_zones
  name                = each.value
  resource_group_name = azurerm_resource_group.groups["common"].name
}

resource "azurerm_private_dns_zone_virtual_network_link" "private_dns_network_links" {
  for_each              = var.private_dns_zones
  name                  = "${module.networking.virtual_network_name}-link"
  resource_group_name   = azurerm_resource_group.groups["common"].name
  private_dns_zone_name = each.value
  virtual_network_id    = module.networking.virtual_network_id
  depends_on            = [azurerm_private_dns_zone.private_dns_zones]
}

module "naming" {
  source                 = "Azure/naming/azurerm"
  version                = "0.2.0"
  suffix                 = ["dev"]
  unique-include-numbers = true
}

# Generate random value for the SQL username
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

# Generate random value for the SQL login password
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

# Create resource groups
resource "azurerm_resource_group" "groups" {
  for_each = {
    "networking" = { name = "rg-project-${var.env}-${random_string.suffix.result}-networking", location = var.region }
    "database"   = { name = "rg-project-${var.env}-${random_string.suffix.result}-database", location = var.region }
    "redis"      = { name = "rg-project-${var.env}-${random_string.suffix.result}-redis", location = var.region }
    "appfe"      = { name = "rg-project-${var.env}-${random_string.suffix.result}-appfe", location = var.region }
    "appbe"      = { name = "rg-project-${var.env}-${random_string.suffix.result}-appbe", location = var.region }
    "storage"    = { name = "rg-project-${var.env}-${random_string.suffix.result}-storage", location = var.region }
    "keyvault"    = { name = "rg-project-${var.env}-${random_string.suffix.result}-keyvault", location = var.region }
    "common"     = { name = "rg-project-${var.env}-${random_string.suffix.result}-common", location = var.region }
  }
  name     = each.value.name
  location = each.value.location
}

resource "azuread_group" "projectadgroup1" {
  display_name     = "Agency-AAD-Admins"
  security_enabled = true
}

resource "azurerm_role_assignment" "role-assignments" {
  for_each = {
    networking = azurerm_resource_group.groups["networking"].id,
    database   = azurerm_resource_group.groups["database"].id,
    redis      = azurerm_resource_group.groups["redis"].id,
    appfe      = azurerm_resource_group.groups["appfe"].id,
    appbe      = azurerm_resource_group.groups["appbe"].id,
    storage    = azurerm_resource_group.groups["storage"].id,
    keyvault     = azurerm_resource_group.groups["keyvault"].id,
    common     = azurerm_resource_group.groups["common"].id,
  }
  scope                = each.value
  role_definition_name = "Contributor"
  principal_id         = azuread_group.projectadgroup1.object_id
}

module "vault-resources" {
  source                     = "./modules/vault-resources"
  vault_name                 = "kv-project-${var.env}-${random_string.suffix.result}"
  location                   = var.region
  resource_group_name        = azurerm_resource_group.groups["keyvault"].name
  sku_name                   = "standard"
  private_dns_zone_ids       = [azurerm_private_dns_zone.private_dns_zones["privatelink-vaultcore-azure-net"].id]
  virtual_network_subnet_ids = [module.networking.snet-project-vault-id]
  sql_username_secret_name   = "kv-secret--${var.env}-sqluname-${random_string.suffix.result}"
  sql_username_secret_value  = random_string.projectsqlrand1.result
  sql_password_secret_name   = "kv-secret--${var.env}-sqlpwd-${random_string.suffix.result}"
  sql_password_secret_value  = random_password.projectsqlrand2.result
  environment                = var.env
}

module "networking" {
  source               = "./modules/networking-resources"
  virtual_network_name = "vnet-project-${var.env}-${random_string.suffix.result}1"
  resource_group_name  = azurerm_resource_group.groups["networking"].name
  location             = var.region
  vnet_address_space   = var.vnet_range
  subnets              = var.subnets
}

module "database-resources" {
  source                       = "./modules/database-resources"
  server_name                  = "sql-project-${var.env}-${random_string.suffix.result}"
  resource_group_name          = azurerm_resource_group.groups["database"].name
  location                     = var.region
  administrator_login          = module.vault-resources.sql_username_secret_value
  administrator_login_password = module.vault-resources.sql_password_secret_value
  vnet_rule_name               = "vnet-rule-project-${var.env}-${random_string.suffix.result}"
  vnet_rule_subnet_id          = module.networking.snet-project-sqlserver-id
  db_name                      = "sqldb-project-${var.env}-${random_string.suffix.result}"
  max_size_gb                  = var.max_db_size
  sku_name                     = var.db_sku
  priv_svc_connection_name     = "psc-db-${var.env}"
  private_dns_zone_name        = "privatelink.database.windows.net"
  private_dns_zone_ids         = [azurerm_private_dns_zone.private_dns_zones["privatelink-database-windows-net"].id]
  endpoint_name                = "pe-db-${var.env}"
  endpoint_subnet_id           = module.networking.snet-project-sqlserver-id
  environment                  = var.env
}

module "application-resources-fe" {
  source                   = "./modules/application-resources"
  asp_name                 = "asp-project-${var.env}-${random_string.suffix.result}1fe"
  resource_group_name      = azurerm_resource_group.groups["appfe"].name
  location                 = var.region
  sku_name                 = "B1"
  app_name                 = "app-project-${var.env}-${random_string.suffix.result}1fe"
  instrumentation_key      = azurerm_application_insights.app-insight.instrumentation_key
  managed_id_role          = "Contributor"
  app_subnet_id            = module.networking.snet-project-appservice-fe-vnet-id
  private_dns_zone_name    = "privatelink.azurewebsites.net"
  private_dns_zone_ids     = [azurerm_private_dns_zone.private_dns_zones["privatelink-app-azure-net"].id]
  vnet_id                  = module.networking.virtual_network_id
  priv_svc_connection_name = "psc-fe-${var.env}"
  endpoint_subnet_id       = module.networking.snet-project-appservice1-fe-privendp-id
  endpoint_name            = "pe-fe-${var.env}"
  environment              = var.env
}

module "application-resources-be" {
  source                   = "./modules/application-resources"
  asp_name                 = "asp-project-${var.env}-${random_string.suffix.result}2be"
  resource_group_name      = azurerm_resource_group.groups["appbe"].name
  location                 = var.region
  sku_name                 = "B1"
  app_name                 = "app-project-${var.env}-${random_string.suffix.result}2be"
  app_subnet_id            = module.networking.snet-project-appservice2-be-vnet-id
  instrumentation_key      = azurerm_application_insights.app-insight.instrumentation_key
  managed_id_role          = "Contributor"
  private_dns_zone_name    = "privatelink.azurewebsites.net"
  private_dns_zone_ids     = [azurerm_private_dns_zone.private_dns_zones["privatelink-app-azure-net"].id]
  vnet_id                  = module.networking.virtual_network_id
  priv_svc_connection_name = "psc-be-${var.env}"
  endpoint_subnet_id       = module.networking.snet-project-appservice2-be-privendp-id
  endpoint_name            = "pe-be-${var.env}"
  environment              = var.env
}

resource "azurerm_log_analytics_workspace" "appworkspace" {
  name                = "log-${var.env}-apps"
  location            = var.region
  resource_group_name = azurerm_resource_group.groups["common"].name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "app-insight" {
  name                = "appi-${var.env}-apps"
  location            = var.region
  resource_group_name = azurerm_resource_group.groups["common"].name
  workspace_id        = azurerm_log_analytics_workspace.appworkspace.id
  application_type    = "web"
}

module "storage_resources_API" {
  source                   = "./modules/storage-resources"
  storage_account_name     = "stproject${var.env}${random_string.suffix.result}api"
  resource_group_name      = azurerm_resource_group.groups["storage"].name
  location                 = var.region
  account_tier             = "Standard"
  account_replication_type = "LRS"
  allowed_ips              = [ "188.2.186.19" ]
  vnet_subnet_ids          = [
                              module.networking.snet-project-appservice2-be-vnet-id,
                              module.networking.snet-project-appservice2-be-privendp-id
                             ]
  environment              = var.env
  container_name           = "stapi"
  container_access_type    = "private"
}



module "redis-resources" {
  source                             = "./modules/redis-resources"
  name                               = "redis-project-${var.env}-${random_string.suffix.result}1"
  location                           = var.region
  resource_group_name                = azurerm_resource_group.groups["redis"].name
  capacity                           = 0
  family                             = "C"
  sku_name                           = "Basic"
  endpoint_name                      = "pe-redis-${var.env}"
  endpoint_subnet_id                 = module.networking.snet-project-redis-id
  priv_svc_connection_name           = "psc-redis-${var.env}"
  private_dns_zone_name              = "privatelink.redis.cache.windows.net"
  private_dns_zone_ids               = [azurerm_private_dns_zone.private_dns_zones["privatelink-redis-windows-net"].id]
  environment                        = var.env
}

resource "azurerm_network_security_group" "frontendsg" {
  name                = "nsg-project-${var.env}-${random_string.suffix.result}-fe"
  location            = var.region
  resource_group_name = azurerm_resource_group.groups["networking"].name
  tags = {
    subnet = "frontend-vnet"
  }
}

resource "azurerm_network_security_rule" "frontend" {
  name                        = "nsgsr-project--${var.env}-${random_string.suffix.result}-fe"
  priority                    = 500
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "443"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.groups["networking"].name
  network_security_group_name = azurerm_network_security_group.frontendsg.name
}

resource "azurerm_subnet_network_security_group_association" "frontend-asoc" {
  subnet_id                 = module.networking.snet-project-appservice1-fe-privendp-id
  network_security_group_id = azurerm_network_security_group.frontendsg.id
}


resource "azurerm_network_security_group" "frontvnet-to-backprivend" {
  name                = "nsg-project-${var.env}-${random_string.suffix.result}-fe-to-be"
  location            = var.region
  resource_group_name = azurerm_resource_group.groups["networking"].name
  tags = {
    subnet = "fevnet-and-beprivend"
  }
}

resource "azurerm_network_security_rule" "front-to-back-allow" {
  name                        = "nsgsr-project--${var.env}-${random_string.suffix.result}-fe-to-be-allow"
  priority                    = 500
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "443"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = module.networking.snet-project-appservice2-be-privendp-ip-range[0]
  resource_group_name         = azurerm_resource_group.groups["networking"].name
  network_security_group_name = azurerm_network_security_group.frontvnet-to-backprivend.name
}

resource "azurerm_network_security_rule" "front-to-back-deny" {
  name                        = "nsgsr-project--${var.env}-${random_string.suffix.result}-fe-to-be-deny"
  priority                    = 600
  direction                   = "Outbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.groups["networking"].name
  network_security_group_name = azurerm_network_security_group.frontvnet-to-backprivend.name
}


resource "azurerm_subnet_network_security_group_association" "front-to-back-asoc" {
  subnet_id                 = module.networking.snet-project-appservice-fe-vnet-id
  network_security_group_id = azurerm_network_security_group.frontvnet-to-backprivend.id
}

resource "azurerm_network_security_group" "backvnet-redis" {
  name                = "nsg-project-${var.env}-${random_string.suffix.result}-backendvnet-redis"
  location            = var.region
  resource_group_name = azurerm_resource_group.groups["networking"].name
  tags = {
    subnet = "backend-vnet-and-redis"
  }
}

resource "azurerm_network_security_rule" "back-to-redis-allow" {
  name                        = "nsgsr-project--${var.env}-${random_string.suffix.result}-be-redis-allow"
  priority                    = 500
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "6380"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = module.networking.snet-project-redis-ip-range[0]
  resource_group_name         = azurerm_resource_group.groups["networking"].name
  network_security_group_name = azurerm_network_security_group.backvnet-redis.name
}

resource "azurerm_network_security_rule" "back-to-redis-deny" {
  name                        = "nsgsr-project--${var.env}-${random_string.suffix.result}-be-redis-deny"
  priority                    = 600
  direction                   = "Outbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.groups["networking"].name
  network_security_group_name = azurerm_network_security_group.backvnet-redis.name
}

resource "azurerm_subnet_network_security_group_association" "back-to-redis-assoc" {
  subnet_id                 = module.networking.snet-project-appservice2-be-vnet-id
  network_security_group_id = azurerm_network_security_group.backvnet-redis.id
}
/* resource "azurerm_resource_group" "networking" {
  name     = "rg-project-${var.env}-${random_string.suffix.result}networking"
  location = var.region
}
*/

/* resource "azurerm_role_assignment" "projectras-database" {
  scope                = azurerm_resource_group.database.id
  role_definition_name = "Contributor"
  principal_id         = azuread_group.projectadgroup1.object_id
} */

/* resource "azurerm_role_assignment" "projectras-main" {
  scope                = module.storage_resources_API.storage_account_id
  role_definition_name = "Contributor"
  principal_id         = module.application-resources-be.web_app_obj_id
} */

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

/* resource "azurerm_subnet" "app-service-fe-vnet123" {
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

/* resource "azurerm_subnet_network_security_group_association" "projectsgassocbe" {
  subnet_id                 = azurerm_subnet.services.id
  network_security_group_id = azurerm_network_security_group.frontendsg.id
} */