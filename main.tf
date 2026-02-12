#creates resource group
resource "random_pet" "rg_name" {
  prefix = var.resource_group_name_prefix
}

resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = random_pet.rg_name.id
}


module "azuresqlserver" {
  source                 = "./modules/azuresqlserver"
  sql_server_name        = "sql2-${azurerm_resource_group.rg.name}"
  resource_group_name    = random_pet.rg_name.id
  location               = var.resource_group_location
  db_version             = "12.0"
  administrator_login    = "sqladmin"
  administrator_password = "password@123!"
  azuread_administrator  = "dbadmins" 
  # old admin EXT#@hellosqlkittygmail.onmicrosoft.com"
  object_id              = "63e659d5-7a8d-4441-8075-4c9060b78e8c"

  use_elastic_pool       = true  
  pool_max_size_gb       = 50
  pool_sku_name          = "StandardPool"
  pool_sku_tier          = "Standard"
  pool_capacity          = 50
  pool_min_capacity      = 0
  pool_max_capacity      = 50

  #create 1 or more dbs 
  databases = [
    {
      name        = "dbnew1-${azurerm_resource_group.rg.name}"
      server_id   = module.azuresqlserver.sql_server_id
      create_mode = "Default"
      sku_name    = "Basic"
      collation   = "SQL_Latin1_General_CP1_CI_AS"
    },
    {
      name        = "dbnew2-${azurerm_resource_group.rg.name}"
      server_id   = module.azuresqlserver.sql_server_id
      create_mode = "Default"
      sku_name    = "Basic"
      collation   = "SQL_Latin1_General_CP1_CI_AS"
    },
  ]
  #create one or more firewall rules 
  firewall_rules = [
    {
      name             = "my-ip"
      start_ip_address = "11.11.11.11"
      end_ip_address   = "11.11.11.11"
    },
    {
      name             = "allow-azure-services"
      start_ip_address = "0.0.0.0"
      end_ip_address   = "0.0.0.0"
    }
  ]

  depends_on = [azurerm_resource_group.rg]
}

module "elasticjobs" {
  source              = "./modules/elasticjobs"
  resource_group_name = random_pet.rg_name.id
  location            = var.resource_group_location
  sql_server_id       = module.azuresqlserver.sql_server_id
  sql_server_name     = module.azuresqlserver.sql_server_name
  elastic_pool_name   = module.azuresqlserver.elastic_pool_name

  depends_on = [azurerm_resource_group.rg]
}



/* if you need to create multiple sql servers/db to test something 

variable "sql_servers" {
  type = list(string)
  default = [
    "sqlserver1",
    "sqlserver2"
  ]
}

module "azuresqlserver" {
  for_each = toset(var.sql_servers)

  source = "./modules/azuresqlserver"
  sql_server_name              = "${each.value}-${azurerm_resource_group.rg.name}"
  resource_group_name          = random_pet.rg_name.id
  location                     = var.resource_group_location
  db_version                   = "12.0"
  administrator_login          = "sqladmin"
  administrator_password       = "password@123!"
  azuread_administrator        = "jbranch74_msn.com#EXT#@hellosqlkittygmail.onmicrosoft.com"
  object_id                    = "edd56623-e123-43ef-b847-71443ac454a0"
  
  firewall_rules = [
    {
      name             = "my-ip"
      start_ip_address = "11.11.11.11"
      end_ip_address   = "11.11.11.11"
    },
    {
      name             = "allow-azure-services"
      start_ip_address = "0.0.0.0"
      end_ip_address   = "0.0.0.0"
    }
  ]
  
  databases = [] # Initial databases array will be filled dynamically later
}

resource "azurerm_mssql_database" "exampledb" {
  for_each = toset(var.sql_servers)

  name         = "dbnew-${each.value}-${azurerm_resource_group.rg.name}"
  server_id    = module.azuresqlserver[each.key].sql_server_id  # Referencing the created server
  create_mode  = "Default"
  sku_name     = "Basic"
  collation    = "SQL_Latin1_General_CP1_CI_AS"
  
  depends_on = [module.azuresqlserver]  # Ensure the SQL server is created before databases
}
*/