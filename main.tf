#creates resource group
resource "random_pet" "rg_name" {
  prefix = var.resource_group_name_prefix
}

resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = random_pet.rg_name.id
} 
 
# creates the azure sql server
resource "azurerm_sql_server" "example" {
  name                         = "sql-${azurerm_resource_group.rg.name}"
  resource_group_name          = random_pet.rg_name.id
  location                     = var.resource_group_location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = "password@123!"
  depends_on = [
    azurerm_resource_group.rg
  ]
} 

# creates the azure sql db
resource "azurerm_sql_database" "example" {
  name                             = "db-${azurerm_resource_group.rg.name}"
  resource_group_name              = random_pet.rg_name.id
  location                         = var.resource_group_location
  server_name                      = azurerm_sql_server.example.name
  edition                          = "Basic"
  collation                        = "SQL_Latin1_General_CP1_CI_AS"
  create_mode                      = "Default"
  requested_service_objective_name = "Basic"
  depends_on = [
     azurerm_sql_server.example
   ]
}

# enables access to your db.  change out the IP to match your IP. 
resource "azurerm_sql_firewall_rule" "example" {
  name                = "my-ip"
  resource_group_name = random_pet.rg_name.id
  server_name         = azurerm_sql_server.example.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
  depends_on = [
     azurerm_sql_database.example
   ]
}




