subnets = {
  snet-project-appservice-fe-vnet = {
    cidr               = ["10.0.1.0/24"]
    service_delegation = true
  }
  snet-project-appservice2-be-vnet = {
    cidr               = ["10.0.2.0/24"]
    service_delegation = true
  }
  snet-project-appservice1-fe-privendp = {
    cidr               = ["10.0.3.0/24"]
    service_delegation = false
  }
  snet-project-appservice2-be-privendp = {
    cidr               = ["10.0.4.0/24"]
    service_delegation = false
  }
  snet-project-redis = {
    cidr               = ["10.0.5.0/24"]
    service_delegation = false
  }
  snet-project-sqlserver = {
    cidr               = ["10.0.6.0/24"]
    service_delegation = false
  }
  snet-project-vault = {
    cidr               = ["10.0.7.0/24"]
    service_delegation = false
  }
}

private_dns_zones = {
  privatelink-app-azure-net         = "privatelink.azurewebsites.net"
  privatelink-database-windows-net  = "privatelink.database.windows.net"
  privatelink-blob-core-windows-net = "privatelink.blob.core.windows.net"
  privatelink-vaultcore-azure-net   = "privatelink.vaultcore.azure.net"
  privatelink-redis-windows-net     = "privatelink.redis.cache.windows.net"
}

/* subscription_id = "09d7927e-346e-45cc-ace4-c17cd778f190" */