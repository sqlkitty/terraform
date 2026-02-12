module "azureactiongroup" {
  source = "../azureactiongroup"
  resource_group_name = var.resource_group_name
}

/*
# creates alert for max dtu 80%
resource "azurerm_monitor_metric_alert" "alertdtu80" {
  name                = "db-DTUalertMax80"
  resource_group_name = azurerm_mssql_server.example.resource_group_name #var.resource_group_name
  scopes              = ["/subscriptions/244eb28e-a9b8-42d4-9260-c0c553ae92e1"]
  description         = "db DTU alert greater than 80%"
  target_resource_type = "Microsoft.Sql/servers/databases"
  target_resource_location = var.location
  severity            = 2
  
  criteria { 
    metric_namespace = "Microsoft.Sql/servers/databases"
    metric_name      = "dtu_consumption_percent"
    aggregation      = "Maximum"
    operator         = "GreaterThan"
    threshold        = 80
    #frequency        = 
    # window_size must be greater than frequency
    #window_size      = 
  }

  action {
    action_group_id = module.azureactiongroup.action_group_id
  }
}

# creates alert for max dtu 95%
resource "azurerm_monitor_metric_alert" "alertdtu95" {
  name                = "db-DTUalertMax95"
  resource_group_name = var.resource_group_name
  scopes              = ["/subscriptions/244eb28e-a9b8-42d4-9260-c0c553ae92e1"]
  description         = "db DTU alert greater than 95%"
  target_resource_type = "Microsoft.Sql/servers/databases"
  target_resource_location = var.location
  severity            = 0
  
  criteria { 
    metric_namespace = "Microsoft.Sql/servers/databases"
    metric_name      = "dtu_consumption_percent"
    aggregation      = "Maximum"
    operator         = "GreaterThan"
    threshold        = 95
  }

  action {
    action_group_id = module.azureactiongroup.action_group_id #azurerm_monitor_action_group.ag.id
  }
}


# creates alert for disk usage 80%
resource "azurerm_monitor_metric_alert" "alertdisk80" {
  name                = "db-diskalert80"
  resource_group_name = var.resource_group_name
  scopes              = ["/subscriptions/244eb28e-a9b8-42d4-9260-c0c553ae92e1"]
  description         = "db disk space alert greater than 80%"
  target_resource_type = "Microsoft.Sql/servers/databases"
  target_resource_location = var.location
  severity            = 2
  
  criteria { 
    metric_namespace = "Microsoft.Sql/servers/databases"
    metric_name      = "storage_percent"
    aggregation      = "Maximum"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = module.azureactiongroup.action_group_id
  }
}

# creates alert for disk usage 95%
resource "azurerm_monitor_metric_alert" "alertdisk95" {
  name                = "db-diskalert95"
  resource_group_name = var.resource_group_name
  scopes              = ["/subscriptions/244eb28e-a9b8-42d4-9260-c0c553ae92e1"]
  description         = "db disk space alert greater than 95%"
  target_resource_type = "Microsoft.Sql/servers/databases"
  target_resource_location = var.location
  severity            = 0
  
  criteria { 
    metric_namespace = "Microsoft.Sql/servers/databases"
    metric_name      = "storage_percent"
    aggregation      = "Maximum"
    operator         = "GreaterThan"
    threshold        = 95
  }

  action {
    action_group_id = module.azureactiongroup.action_group_id
  }
}

*/