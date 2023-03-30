# creates alert action group 
resource "azurerm_monitor_action_group" "ag" {
  name                = "dbactiongroup"
  resource_group_name = random_pet.rg_name.id
  short_name          = "dbactgrp"

  email_receiver {
    name                    = "sendtome"
    email_address           = "hellosqlkitty@gmail.com"
    use_common_alert_schema = true
  }
  depends_on = [
     azurerm_sql_database.example
   ]

} 
 
# creates alert for max dtu 80%
resource "azurerm_monitor_metric_alert" "alertdtu80" {
  name                = "db-DTUalertMax80"
  resource_group_name = random_pet.rg_name.id
  scopes              = ["/subscriptions/4290e3cb-9352-4732-b94f-4d976370691c"]
  description         = "db DTU alert greater than 80%"
  target_resource_type = "Microsoft.Sql/servers/databases"
  target_resource_location = var.resource_group_location
  severity            = 2
  
  criteria { 
    metric_namespace = "Microsoft.Sql/servers/databases"
    metric_name      = "dtu_consumption_percent"
    aggregation      = "Maximum"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.ag.id
  }
  depends_on = [
     azurerm_sql_database.example
   ]
}

# creates alert for max dtu 95%
resource "azurerm_monitor_metric_alert" "alertdtu95" {
  name                = "db-DTUalertMax95"
  resource_group_name = random_pet.rg_name.id
  scopes              = ["/subscriptions/4290e3cb-9352-4732-b94f-4d976370691c"]
  description         = "db DTU alert greater than 95%"
  target_resource_type = "Microsoft.Sql/servers/databases"
  target_resource_location = var.resource_group_location
  severity            = 0
  
  criteria { 
    metric_namespace = "Microsoft.Sql/servers/databases"
    metric_name      = "dtu_consumption_percent"
    aggregation      = "Maximum"
    operator         = "GreaterThan"
    threshold        = 95
  }

  action {
    action_group_id = azurerm_monitor_action_group.ag.id
  }
}

# creates alert for disk usage 80%
resource "azurerm_monitor_metric_alert" "alertdisk80" {
  name                = "db-diskalert80"
  resource_group_name = random_pet.rg_name.id
  scopes              = ["/subscriptions/4290e3cb-9352-4732-b94f-4d976370691c"]
  description         = "db disk space alert greater than 80%"
  target_resource_type = "Microsoft.Sql/servers/databases"
  target_resource_location = var.resource_group_location
  severity            = 2
  
  criteria { 
    metric_namespace = "Microsoft.Sql/servers/databases"
    metric_name      = "storage_percent"
    aggregation      = "Maximum"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.ag.id
  }
  depends_on = [
     azurerm_sql_database.example
   ]
}

# creates alert for disk usage 95%
resource "azurerm_monitor_metric_alert" "alertdisk95" {
  name                = "db-diskalert95"
  resource_group_name = random_pet.rg_name.id
  scopes              = ["/subscriptions/4290e3cb-9352-4732-b94f-4d976370691c"]
  description         = "db disk space alert greater than 95%"
  target_resource_type = "Microsoft.Sql/servers/databases"
  target_resource_location = var.resource_group_location
  severity            = 0
  
  criteria { 
    metric_namespace = "Microsoft.Sql/servers/databases"
    metric_name      = "storage_percent"
    aggregation      = "Maximum"
    operator         = "GreaterThan"
    threshold        = 95
  }

  action {
    action_group_id = azurerm_monitor_action_group.ag.id
  }
  depends_on = [
     azurerm_sql_database.example
   ]
}