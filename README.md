# Terraform 

# Getting Started with Terraform for Azure SQL Database

I did it like this. Is it the right way? Maybe. I'm giving you my steps so you know how this process could work.

## Initial Setup

1. On GitHub.com, create a repository for Terraform
2. Clone this repository with GitHub Desktop to a folder on your local machine
3. Open that folder in VSCode
4. Open the Terminal by clicking the Terminal menu item then choose **New Terminal**
5. Run `az login` – this will log you into your Azure account so that you can create resources with Terraform

## Terraform Components

Now you can create a few files to support your Terraform process:

- **main.tf** – This holds the code for the resources you will create. In my case, I put the resource group and server, and db setup in this file.
- **output.tf** – This holds anything you want to output to the terminal after Terraform runs.
- **providers.tf** – This holds whatever providers Terraform needs to run.
- **variables.tf** – This holds variables you can use in main.tf.
- **alerts.tf** – This holds the code for creating the alerts. I didn't want my main.tf getting really long, so I split these out.

### providers.tf

Let's look at what each of these files will contain starting with providers.tf. Terraform will error if you don't provide it with what providers it should use. Thank you, Microsoft, for this helpful tutorial. Also, a lot of helpful examples in the [Terraform GitHub repository](https://github.com/hashicorp/terraform). In this case, I will use these providers:

```hcl
terraform {
  required_version = ">=0.12"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}
}
```

### output.tf

Next up is output.tf. You don't have to output anything. I chose to output the resource group name, SQL Server fully qualified domain name, and database name.

```hcl
output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "sql_server_fqdn" {
  value = azurerm_mssql_server.example.fully_qualified_domain_name
}

output "database_name" {
  value = azurerm_mssql_database.example.name
}
```

### variables.tf

Next, we have variables.tf. I've stored a couple of variables here.

```hcl
variable "resource_group_location" {
  default     = "eastus2"
  description = "Location of the resource group."
}

variable "resource_group_name_prefix" {
  default     = "rg"
  description = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}
```

### main.tf

Then we get to main.tf, which holds all the resources I want to create. Let's step through this one a bit to see what we have.

## Creating Resources

To begin with, I want to create a resource group to hold all my resources. I've also used random_pet so I always get a unique name. This way I could share the code with you, and you can run it without issue.

The following code will create a resource group with the naming convention `rg-hopeful-monkey`. In my case, it's a very fitting description of me this week.

```hcl
resource "random_pet" "rg_name" {
  prefix = var.resource_group_name_prefix
}

resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = random_pet.rg_name.id
}
```

### Testing Terraform

At this point, with all my files and a resource group creation in place, I wanted to test Terraform. Before you start, you must run `terraform init` at the terminal in VSCode. You can't create any resources until after you run this init command. Once the init is complete, you will see a `terraform.tfstate` file in your folder.

Next, you can run `terraform plan`. This will show you if you have any errors and let you know what it will add, change, or destroy. i.e. `Plan: 1 to add, 0 to change, 0 to destroy`. I'm always careful to analyze the details and especially careful with change and destroy.

If the plan looks good, you can move on to `terraform apply`. It will run through a plan and let you know what it plans to add, change, or destroy. In fact, you don't have to run a plan before apply because apply includes plan. The apply option then asks you: **Do you want to perform these actions?** Enter `yes` to apply.

It outputs the process and what it's working on. Then, hopefully, because you've done everything correctly, it says: `Apply complete! Resources: 1 added, 0 changed, 0 destroyed`. It will also output anything you've specified in the output.tf file. So in my case, it added one resource group named `rg-hopeful-monkey`.

## Creating Azure SQL Database

Once we have the resource group, we can add a SQL Server to it. I included the `depends_on` because I want to ensure Terraform doesn't try to create the server until the resource group is set up.

```hcl
resource "azurerm_mssql_server" "example" {
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
```

Then we can add a SQL database to the server. I included the `depends_on` because I want to ensure Terraform doesn't try to create the database until the server is set up.

```hcl
resource "azurerm_mssql_database" "example" {
  name                             = "db-${azurerm_resource_group.rg.name}"
  server_id                        = azurerm_mssql_server.example.id
  create_mode                      = "Default"
  sku_name                         = "Basic"
  collation                        = "SQL_Latin1_General_CP1_CI_AS"
  depends_on = [
     azurerm_mssql_server.example
   ]
}
```

### Firewall Rules

To be able to log into the DB server from SSMS or Azure Data Studio, you will need firewall rules. Get your IP and change the `0.0.0.0` to your IP address.

```hcl
resource "azurerm_mssql_firewall_rule" "example" {
  name                = "my-ip"
  server_id         = azurerm_mssql_server.example.id
  start_ip_address    = "67.164.173.44"
  end_ip_address      = "67.164.173.44"
  depends_on = [
     azurerm_mssql_database.example
   ]
}
```

## Creating Alerts

Now that you have your database in place, you can add alerts to it. First, you will need an action group, so the alerts get sent to you. I chose email alerts, but there are other options.

```hcl
resource "azurerm_monitor_action_group" "ag" {
  name                = "dbactiongroup"
  resource_group_name = random_pet.rg_name.id
  short_name          = "dbactgrp"

  email_receiver {
    name                    = "sendtome"
    email_address           = "email@email.com"
    use_common_alert_schema = true
  }
  depends_on = [
     azurerm_mssql_database.example
   ]
}
```

### Alert Configuration

Now you can create alerts. The alerts I'm most interested in seeing are the DTU percentage and disk usage percentage. I created two alerts for each:

- One for a **warning at 80%**
- One for **critical at 95%**

I want to know before it becomes a huge problem. If for some reason I miss that warning, I get another alert when it is critical. I've included only one alert setup below. To see the rest, visit my GitHub repository. I included the `depends_on` because I want to ensure Terraform doesn't try to create these alerts until the database is set up.

```hcl
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
     azurerm_mssql_database.example
   ]
}
```

## Final Steps

Once I'm done creating all these Terraform resources in files, I run `terraform apply` in the terminal. Then, once I'm happy with the tf files and they've all applied correctly, I will use either VS Code or GitHub Desktop to commit and push them to GitHub.

Now I will receive an email if this threshold is crossed. Hopefully, no more someone telling me there's a problem before I know there is a problem. I may add more alerts, but for now, these basic ones will cover many of the issues that may come up in Azure SQL Database.



### Set Up Auditing

Now that you have your Azure **SQL** Server in place (if you followed the week 3 blog post), you can add auditing to it.

First, you will need a Log Analytics Workspace to store audit data. I chose Log Analytics, but you can also choose Storage or Event Hub.

I love Log Analytics because:

It’s easy to query data with Kusto

You can centralize all your database audit data in one workspace per subscription

Create a Log Analytics Workspace
```hcl
resource "azurerm_log_analytics_workspace" "example" {
    name                = "law-${azurerm_resource_group.rg.name}"
    location            = var.resource_group_location
    resource_group_name = random_pet.rg_name.id
    sku                 = "PerGB2018"
    retention_in_days   = 30
}
```

### Set Up Auditing

This configuration audits all Azure SQL databases on the server in the same way and sends audit data to the Log Analytics Workspace.
```hcl
resource "azurerm_monitor_diagnostic_setting" "example" {
    name                       = "ds-${azurerm_resource_group.rg.name}"
    target_resource_id         = "${azurerm_mssql_server.example.id}/databases/master"
    log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id

    enabled_log {
    category = "SQLSecurityAuditEvents"

    retention_policy {
        enabled = false
        }
    }

    metric {
        category = *AllMetrics*

        retention_policy {
        enabled = false
        }
    }

    lifecycle {
        ignore_changes = [log, metric]
    }
}
```

Enable Extended Auditing (Database Level)
```hcl
resource "azurerm_mssql_database_extended_auditing_policy" "example" {
    database_id            = "${azurerm_mssql_server.example.id}/databases/master"
    log_monitoring_enabled = true
}
```

Enable Extended Auditing (Server Level)
```hcl
resource "azurerm_mssql_server_extended_auditing_policy" "example" {
    server_id              = azurerm_mssql_server.example.id
    log_monitoring_enabled = true
}
```

After creating these Terraform resources, run:

terraform apply

Once everything applies successfully:

Commit your Terraform files

Push them to GitHub (via VS Code or GitHub Desktop)

### Configure Auditing

### Default Audit Action Groups

Azure SQL auditing collects everything happening in the database by default with these audit action groups:

BATCH_COMPLETED_GROUP

SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP

FAILED_DATABASE_AUTHENTICATION_GROUP

For now, I’m leaving my audit action groups as default because I want to:

See all queries hitting the databases

Analyze them for performance improvements

Identify unused objects

To modify audit action groups, you currently need PowerShell.

### Get Current Audit Action Groups

```hcl
Get-AzSqlServerAudit -ResourceGroupName 'rg-hopeful-monkey' -Servername 'sql-rg-hopeful-monkey'

Set Audit Action Groups (Schema & Security Only) Set-AzSqlServerAudit -ResourceGroupName 'rg-hopeful-monkey' ` -ServerName 'sql-rg-hopeful-monkey' ` -AuditActionGroup APPLICATION_ROLE_CHANGE_PASSWORD_GROUP, DATABASE_CHANGE_GROUP, ` DATABASE_OBJECT_CHANGE_GROUP, DATABASE_OBJECT_OWNERSHIP_CHANGE_GROUP, ` DATABASE_OBJECT_PERMISSION_CHANGE_GROUP, ` DATABASE_OWNERSHIP_CHANGE_GROUP, ` DATABASE_PERMISSION_CHANGE_GROUP, DATABASE_PRINCIPAL_CHANGE_GROUP, ` DATABASE_PRINCIPAL_IMPERSONATION_GROUP, ` DATABASE_ROLE_MEMBER_CHANGE_GROUP, ` SCHEMA_OBJECT_CHANGE_GROUP, SCHEMA_OBJECT_OWNERSHIP_CHANGE_GROUP, ` SCHEMA_OBJECT_PERMISSION_CHANGE_GROUP, USER_CHANGE_PASSWORD_GROUP
```

For now, I’m keeping the defaults so I can monitor all database activity. I’ll update this post once I figure out how to configure audit action groups using Terraform.

### Querying Audit Data

### Learn Kusto

Here’s a helpful Kusto tutorial. Kusto is:

Very powerful

Easy to use

Similar to **SQL** (if you already know **SQL**)

Workspace Summary (Deprecated)

The Workspace Summary dashboard is being deprecated, but it has been very useful.

It previously provided a helpful dashboard view of audit data.

Microsoft is replacing it with Workbooks. I’m currently exploring how to recreate the Workspace Summary experience using Workbooks.

For now, I’m still using Workspace Summary since it hasn't been fully removed.

### Running Kusto Queries

In the Log Analytics Workspace:

### Click Logs

Run your Kusto queries

Example 1: Busiest Databases
```hcl
AzureDiagnostics
| summarize QueryCountByDB = count() by database_name_s
```

Example 2: Detailed Activity in the Last Day
```hcl
AzureDiagnostics
| where Category == 'SQLSecurityAuditEvents'
   and TimeGenerated > ago(1d) 
| project
    event_time_t,
    action_name_s,
    database_name_s,
    statement_s,
    server_principal_name_s,
    succeeded_s,
    client_ip_s,
    application_name_s,
    additional_information_s,
    data_sensitivity_information_s
| order by event_time_t desc
```
