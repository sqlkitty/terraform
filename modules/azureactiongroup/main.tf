# creates alert action group 
resource "azurerm_monitor_action_group" "ag" {
  name                = "dbactiongroup"
  resource_group_name = var.resource_group_name
  short_name          = "dbactgrp"

  email_receiver {
    name                    = "sendtome"
    email_address           = "hellosqlkitty@gmail.com"
    use_common_alert_schema = true
  }
  /*depends_on = [
     azurerm_mssql_database.example
   ]*/

}
 