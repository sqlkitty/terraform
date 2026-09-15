/*resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "_%@/'\""
}*/

resource "azurerm_mssql_elasticpool" "pool" {
  count               = var.use_elastic_pool ? 1 : 0
  name                = "${var.sql_server_name}-pool"
  resource_group_name = var.resource_group_name
  location            = var.location
  server_name         = azurerm_mssql_server.example.name
  max_size_gb         = var.pool_max_size_gb
  
  sku {
    name     = var.pool_sku_name
    tier     = var.pool_sku_tier
    capacity = var.pool_capacity
  }
  
  per_database_settings {
    min_capacity = var.pool_min_capacity
    max_capacity = var.pool_max_capacity
  }
}

resource "azurerm_mssql_server" "example" {
  name                         = var.sql_server_name
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = var.db_version
  administrator_login          = var.administrator_login
  administrator_login_password = var.administrator_password  #random_password.password.result
  
  azuread_administrator {
    login_username = var.azuread_administrator
    object_id      = var.object_id
  }
} 


resource "azurerm_mssql_database" "exampledb" {
  for_each = { for idx, db in var.databases : idx => db }

  name         = each.value.name
  server_id    = each.value.server_id
  create_mode  = each.value.create_mode
  sku_name     = var.use_elastic_pool ? null : each.value.sku_name
  collation    = each.value.collation
  elastic_pool_id = var.use_elastic_pool ? azurerm_mssql_elasticpool.pool[0].id : null
}


/*resource "azurerm_mssql_database" "exampledb" {
  for_each = { for idx, db in var.databases : idx => db }

  name         = each.value.name
  server_id    = each.value.server_id
  create_mode  = each.value.create_mode
  sku_name     = each.value.sku_name
  collation    = each.value.collation
}*/

resource "azurerm_mssql_firewall_rule" "examplefirewall" {
  for_each = { for idx, rule in var.firewall_rules : idx => rule }

  name             = "rule-${each.value.name}"
  server_id        = azurerm_mssql_server.example.id
  start_ip_address = each.value.start_ip_address
  end_ip_address   = each.value.end_ip_address
}

