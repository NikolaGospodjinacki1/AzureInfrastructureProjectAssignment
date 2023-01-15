resource "azurerm_redis_cache" "projectredis1" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  capacity                      = var.capacity
  family                        = var.family
  sku_name                      = var.sku_name
  enable_non_ssl_port           = false
  public_network_access_enabled = false
  tags = {
    environment = var.environment
  }
}

resource "azurerm_private_endpoint" "redis_pe" {
  name                = var.endpoint_name
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.endpoint_subnet_id

  private_service_connection {
    name                           = var.priv_svc_connection_name
    private_connection_resource_id = azurerm_redis_cache.projectredis1.id
    subresource_names              = ["redisCache"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = var.private_dns_zone_name
    private_dns_zone_ids = var.private_dns_zone_ids
  }
}

