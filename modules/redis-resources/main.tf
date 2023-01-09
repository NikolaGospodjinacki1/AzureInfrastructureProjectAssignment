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

resource "azurerm_private_dns_zone" "redis" {
  name                = var.dns_zone_name
  resource_group_name = var.resource_group_name
  tags = {
    environment = var.environment
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "redis" {
  name                  = var.dns_zone_virtual_network_link_name
  private_dns_zone_name = azurerm_private_dns_zone.redis.name
  virtual_network_id    = var.virtual_network_id
  resource_group_name   = var.resource_group_name
}