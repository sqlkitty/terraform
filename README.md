# Terraform 

# Getting Started with Terraform for Azure SQL Database

I did it like this. Is it the right way? Maybe. I'm giving you my steps so you know how this process could work.

## Initial Setup

1. On GitHub.com, create a repository for Terraform
2. Clone this repository with GitHub Desktop to a folder on your local machine
3. Open that folder in VSCode
4. Open the Terminal by clicking the Terminal menu item then choose **New Terminal**
5. Run `az login` – this will log you into your Azure account so that you can create resources with Terraform


### Most Common Terraform Commands

* terraform init – Initialize the working directory, download providers, and set up the backend. 
* terraform validate – Check the configuration for syntax errors. 
* terraform fmt – Format Terraform files into standard style. 
* terraform plan – Show what changes Terraform will make without applying them. 
* terraform apply – Apply the planned changes to create or update resources. 
* terraform destroy – Remove all resources defined in the configuration. 
* terraform output – Display output values from the configuration. 
* terraform state list – List all resources Terraform is tracking. 

But I mainly use a subset of these.

### Executing Terraform Commands

If you don’t see your terminal in VS Code, you can go to View –> Terminal to display it. And that opens a terminal at the bottom of the screen.

**terraform init** – Initialize Your Terraform Project Before Terraform can create or manage infrastructure, your working directory needs to be prepared. When you run terraform init, Terraform will:

Set up the backend – This is where Terraform stores the state file that tracks your infrastructure. By default, it’s stored locally in your project folder as terraform.tfstate. Download providers – Terraform uses providers (**AWS**, Azure, **GCP**, Kubernetes, etc.) to talk to different services. It looks at your .tf files, sees which providers you declared, and downloads the correct versions from the Terraform Registry. Install modules – If your configuration uses modules (reusable Terraform code), terraform init will fetch them. Important: You must run terraform init at least once before terraform plan or terraform apply. Also, if you change provider versions or backend settings, you should run it again to refresh everything.


**terraform plan** – Preview What Changes Terraform Will Make The terraform plan command shows you exactly what Terraform will do before it makes any changes to your infrastructure. It compares the current state of your resources (from the state file) with your configuration files and then displays a list of additions, changes, and deletions it would make to bring your infrastructure in line with your code.

Resources to be created (marked with a plus sign +) Resources to be updated (marked with a tilde ~) Resources to be destroyed (marked with a minus sign -) Running terraform plan is a good safety step because it lets you confirm that Terraform understood your intentions before you make changes. Many people run plan before they apply to avoid surprises.

In my case, I used to always run terraform plan first, but I don’t anymore because terraform apply itself shows you the same plan and still asks for approval before making changes. This means if you trust your configuration and are comfortable skipping the extra step, you can just run terraform apply directly and approve the plan when prompted.

Before you can run terraform plan, you need to run az login (in my case, since I’m using Azure with Terraform) to authenticate to your subscription.

After you run terraform plan, it will show you things like these, but it all depends on whether you’ve changed things outside Terraform or not, and if you are adding new things. But just to give you an example of some of the results I’m seeing right now. I blew away an entire resource group, but didn’t use Terraform. I don’t recommend doing it that way, especially if you have your resources in Terraform, but I felt like doing that in my personal environment one day.

I don’t want to add all that stuff back in, so in that case, I move any Terraform files, I don’t want to be applied into a subfolder. My ignorefornow subfolder holds anything that’s broken or I don’t want to use currently. I also comment out things in my main.tf file, so they won’t try to create it if I don’t want them back in place.

But the good news is, there aren’t any errors with my plan, so I’m going to move on to apply.

**terraform apply** – Apply Changes to Create or Update Infrastructure The terraform apply command is the one that makes changes to your infrastructure. One of the best things about terraform apply is that it first shows you a plan of what it will do. You’ll see a list of resources that will be added, changed, or destroyed before any action is taken, giving you a chance to review everything carefully.

I like this command the most because it combines planning and applying in one step. I like this one the best because it plans and then displays everything it’s going to add, change, or destroy. I always carefully look at the destroy in particular, but also the changes. Additions aren’t so risky.

I moved some of my tf files into the ignorefornow folder and commented out some things from my main.tf, so that I only have a few things to destroy and the one thing I want to add at this point. Now, with terraform apply, it asks you if you want to perform these actions.

I typed yes because I was ready to apply these changes, and it applied my changes successfully.

Also, I wanted a new random pet name for my resource group. Note for myself: I can do this with terraform apply -replace=”random_pet.rg_name”

**terraform destroy** – Delete Infrastructure Created by Terraform The terraform destroy command is used to completely remove resources that Terraform manages. It reads your current state and configuration files and then deletes everything defined in your project.

This command is particularly useful when you want to clean up test environments or remove a bunch of resources at once without manually deleting each one. Because destroy can be destructive (imagine that!), Terraform will first show you a plan of what will be removed and ask for your approval before actually deleting anything.

I rarely use terraform destroy, but it’s handy if you need to start over or avoid leaving unused resources running.

What if you only want to destroy one thing? Comment it out from your code or move that file into a subfolder. It’s not recommended to use the -target flag on the destroy command because it can leave your infra in an inconsistent state.

**terraform fmt** – Format .tf files for Readability and Consistency The terraform fmt command automatically formats your Terraform configuration files so they follow the standard style and conventions. It ensures that indentation, spacing, and alignment are consistent across all .tf files in your project.

I think this could be one of my new favorite Terraform commands because it’s so simple but so effective. It doesn’t change the logic of your configuration, only the formatting, but it makes a big difference in readability.

You can run it on a single file: terraform fmt main.tf

Or on your entire project: terraform fmt

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
```

Set Audit Action Groups (Schema & Security Only) 
```hcl
Set-AzSqlServerAudit -ResourceGroupName 'rg-hopeful-monkey' ` -ServerName 'sql-rg-hopeful-monkey' ` -AuditActionGroup APPLICATION_ROLE_CHANGE_PASSWORD_GROUP, DATABASE_CHANGE_GROUP, ` DATABASE_OBJECT_CHANGE_GROUP, DATABASE_OBJECT_OWNERSHIP_CHANGE_GROUP, ` DATABASE_OBJECT_PERMISSION_CHANGE_GROUP, ` DATABASE_OWNERSHIP_CHANGE_GROUP, ` DATABASE_PERMISSION_CHANGE_GROUP, DATABASE_PRINCIPAL_CHANGE_GROUP, ` DATABASE_PRINCIPAL_IMPERSONATION_GROUP, ` DATABASE_ROLE_MEMBER_CHANGE_GROUP, ` SCHEMA_OBJECT_CHANGE_GROUP, SCHEMA_OBJECT_OWNERSHIP_CHANGE_GROUP, ` SCHEMA_OBJECT_PERMISSION_CHANGE_GROUP, USER_CHANGE_PASSWORD_GROUP
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


## Azure SQL DB Module Structure 
A well-structured Terraform module for Azure SQL DB typically consists of the following elements:

Main Configuration Files: main.tf, variables.tf, outputs.tf 
Helper Files: (if necessary) locals.tf, providers.tf, etc. 
If you want to learn more about the basics of Terraform, you can visit my previous blog post.

Writing the Azure SQL DB Module I used to have a sqldb.tf file that held all the TF to create my Azure SQL databases and associated bits like the server, the databases, and the firewall rules. It’s considered best practice to modulize your Terraform. I may also add more to this module, like alerts and auditing, but I’m keeping those un-modulized for now.

You’ll typically organize your code into several files within a directory to create a Terraform module for provisioning Azure SQL DB. Here’s an example of how you might structure your module. You can name your module what you like. I chose azuresqlserver.

### Directory Structure

azuresqlserver/
    ├── main.tf
    ├── variables.tf
    └── outputs.tf

### Module File Explanation

main.tf This file contains the actual Azure resources and their configurations using the Azure provider. Here’s an example of how it might look for Azure **SQL** DB:

# main.tf

```hcl
provider "azurerm" { features {} }

resource "random_password" "password" {
    length           = 16
    special          = true

resource "azurerm_mssql_server" "example" {
    name                         = var.sql_server_name
    resource_group_name          = var.resource_group_name
    location                     = var.location
    version                      = var.db_version
    administrator_login          = var.administrator_login
    administrator_login_password = var.administrator_password  
  
    azuread_administrator {
    login_username = var.azuread_administrator
    object_id      = var.object_id
    }
}

resource "azurerm_mssql_database" "exampledb" { for_each = { for idx, db in var.databases : idx => db }

    name         = each.value.name
    server_id    = each.value.server_id
    create_mode  = each.value.create_mode
    sku_name     = each.value.sku_name
    collation    = each.value.collation
}

resource "azurerm_mssql_firewall_rule" "examplefirewall" { for_each = { for idx, rule in var.firewall_rules : idx => rule }

    name             = *rule-${each.value.name}*
    server_id        = azurerm_mssql_server.example.id
    start_ip_address = each.value.start_ip_address
    end_ip_address   = each.value.end_ip_address
}
```

variables.tf This file defines input variables for your module. These variables can be customized when using the module in the main Terraform configuration. Based on the main.tf file above you will need these variables:

# variables.tf

```hcl
variable "resource_group_name" {
    description = "Name of the Azure resource group"
    type        = string
}

variable "sql_server_name" {
    description = "Name of the Azure SQL Server"
    type        = string
}

variable "location" {
    description = "Azure region"
    type        = string
}

variable "db_version" {
    description = "Version of the Azure SQL Database"
    type        = string
}

variable "administrator_login" {
    description = "Admin of the Azure SQL Database"
    type        = string
}

variable "administrator_password" {
    description = "Admin of the Azure SQL Database"
    type        = string
}

variable "azuread_administrator" {
    description = "AD Admin of the Azure SQL Database"
    type        = string
}

variable "object_id" {
    description = "Object ID for AD Admin"
    type        = string
}
  
variable "firewall_rules" {
    description = "List of firewall rules"
    type        = list(object({
    name             = string
    start_ip_address = string
    end_ip_address   = string
    }))
}

variable "databases" {
    description = "List of databases"
    type        = list(object({
    name        = string
    server_id   = string
    create_mode = string
    sku_name    = string
    collation   = string
    }))
}
```

outputs.tf This file specifies the output values that the module will provide after deployment. These outputs can be used in the main Terraform configuration or by other modules that consume this module. I only output one item here because I need to use it to refer to the server ID in another call.

# outputs.tf

output "sql_server_id" {
    value = azurerm_mssql_server.example.id
}

Using the Module To use this module in your main Terraform configuration, you can add this to your main.tf file or whatever file you want to use for creating Azure SQL DB, as you don’t have to use main.tf This code snippet shows how to use the azuresqlserver module, providing specific values for the required variables. Adjust the variable values according to your Azure setup and requirements:

```hcl
#creates resource group resource "random_pet" "rg_name" { prefix = var.resource_group_name_prefix }

resource "azurerm_resource_group" "rg" {
    location = var.resource_group_location
    name     = random_pet.rg_name.id
}

#reference azuresqldb module to create azuresqlserver 
module "azuresqlserver" {
    source = "./modules/azuresqlserver"
    sql_server_name              = "sql2-${azurerm_resource_group.rg.name}"
    resource_group_name          = random_pet.rg_name.id
    location                     = var.resource_group_location
    db_version                   = "12.0"
    administrator_login          = "sqladmin"
    administrator_password       = "passwordstr0ng!"
    azuread_administrator        = "jb.onmicrosoft.com"
    object_id                    = "edd56623-e123"
    #create 1 or more dbs 
    databases = [
    {
    name         = "dbnew1-${azurerm_resource_group.rg.name}"
    server_id    = module.azuresqlserver.sql_server_id
    create_mode  = "Default"
    sku_name     = "Basic"
    collation    = "SQL_Latin1_General_CP1_CI_AS"
    },
    {
    name         = "dbnew2-${azurerm_resource_group.rg.name}"
    server_id    = module.azuresqlserver.sql_server_id
    create_mode  = "Default"
    sku_name     = "Basic"
    collation    = "SQL_Latin1_General_CP1_CI_AS"
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
}
```

Before applying this, you must run terraform init to install the module.



# Terraform Elastic Jobs

Depending on whether you have an elastic pool or want one, you can leave out the pool part. However, you will need an Azure SQL db to hold the jobs in the elastic agent. So here, I will create a pool and a server. You can put the db on an existing server in an existing resource group, too, if you want. I’m creating a new resource group to delete after testing, an Azure SQL Server, an elastic pool, and an Azure SQL db. You must have the SQL db, you can use existing resources for everything else.

Note: You will need at least a capacity of 50 in an elastic pool or an S1 if using a database outside of a pool. These are the minimum requirements for an Elastic Agent with an Azure SQL Database.

```
resource "azurerm_resource_group" "elasticjobrg" {
  location = var.resource_group_location
  name     = "elasticjobrg"
} 

resource "azurerm_mssql_server" "server" {
    name                         = "elastic-${azurerm_resource_group.elasticjobrg.name}"
    resource_group_name          = azurerm_resource_group.elasticjobrg.name
    location                     = azurerm_resource_group.rg.location
    version                      = "12.0"
    administrator_login          = "adminuser"
    administrator_login_password = "password@123!"
    azuread_administrator {
      login_username = "yourgroup/user"
      object_id      = "itsobjectid"
    }
}
resource "azurerm_mssql_elasticpool" "example" {
  name                = "sqlelasticpool"
  resource_group_name = azurerm_resource_group.elasticjobrg.name
  location            = azurerm_resource_group.rg.location
  server_name         = azurerm_mssql_server.server.name

  sku {
    name     = "StandardPool"
    tier     = "Standard"
    capacity = 50
  }

   max_size_gb = 50

  per_database_settings {
    min_capacity = 0
    max_capacity = 50
  }
}

resource "azurerm_mssql_database" "database" {
    name              = "dbelastic-${azurerm_resource_group.elasticjobrg.name}"
    server_id         = azurerm_mssql_server.server.id
    collation         = "SQL_Latin1_General_CP1_CI_AS"
    /*
    this is getting set with the pool
    sku_name          = "S1"
    max_size_gb       = 10  # Adjust this value as needed
    */
    elastic_pool_id   = azurerm_mssql_elasticpool.example.id
}

resource "azurerm_mssql_firewall_rule" "azure-services-rule" {
  name                = "allow-azure-services"
  server_id           = azurerm_mssql_server.server.id
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
  depends_on = [
     azurerm_mssql_server.server
   ]
} 
```

So now we have the basics setup, so we can create the agent and jobs.

### Creating a Managed Identity

We also need a managed identity so the Elastic Job Agent can access the databases, including its own db and any databases you want to run jobs against.

```
resource "azurerm_user_assigned_identity" "managed_identity" {
  name                = "ElasticAgentJobsManagedID"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.elasticjobrg.name
}
```

Then, we need to add it to our db. I’m giving it owner as I want it to read/write and execute stored procs. I trust it’s not going to be used for elevated purposes. I’m going to have it run Ola stats updates and index maintenance. You might wonder why it needs db_owner, and I wondered about this, too. I tried with lower perms, but it couldn’t see certain tables. I needed it to see with lesser perms, which was very odd. Note you need to connect with an AD (Entra) account to add this, you can’t add it if you are logged in as the server admin.

```sql
CREATE USER ElasticAgentJobsManagedID FROM EXTERNAL PROVIDER;
ALTER ROLE db_owner ADD MEMBER ElasticAgentJobsManagedID;
```

You will also need to add this to master db if you are wanting the job to run against all the dbs on the same server. Otherwise, you will get an error — Login failed for user ‘<token-identified principal>’.

```sql
CREATE USER ElasticAgentJobsManagedID FROM EXTERNAL PROVIDER;
```

You will also need the Ola scripts in whatever databases you want to run the job in.

You can get these [from Ola](https://ola.hallengren.com/sql-server-index-and-statistics-maintenance.html) directly.

## Creating the Elastic Job Agent

Here’s where we need to add azapi_resource to the providers. For your reference, here is my providers.tf file.

```
terraform {
  required_version = ">=0.12"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.74.0"
    }

    azapi = {
      source = "Azure/azapi"
    }
  }
} 

provider "azurerm" {
  features {
  }
}

provider "azapi" {
}
```

Now, I will create the Elastic Job Agent. This will create elastic jobs agent with default JA100 setting 

```
resource "azapi_resource" "elasticjobagent" {
  type = "Microsoft.Sql/servers/jobAgents@2023-05-01-preview"
  name = "elasticagent-${azurerm_resource_group.elasticjobrg.name}"
  location = azurerm_resource_group.rg.location
  parent_id = azurerm_mssql_server.server.id
  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.managed_identity.id]
  }
  body = jsonencode({
    properties = {
      databaseId = azurerm_mssql_database.database.id
    }    
  })
}
```

I will also need to set up a target group and add servers and/or databases to it, so those will have jobs executed against them. You can include or exclude members. I have more info on that in the other posts referenced at the top of this post. Microsoft provides guidance on the parameters in members [here](https://learn.microsoft.com/en-us/azure/templates/microsoft.sql/servers/jobagents/targetgroups?pivots=deployment-language-terraform#jobtarget-2).

```
resource "azapi_resource" "elasticjobstargetgroups" {
  type = "Microsoft.Sql/servers/jobAgents/targetGroups@2023-05-01-preview"
  name = "AzureSQLDBs"
  parent_id = azapi_resource.elasticjobagent.id
  body = jsonencode({
    properties = {
      members = [
        {
          /* use this if your db is in an elastic pool */ 
          elasticPoolName = azurerm_mssql_elasticpool.example.name  
          membershipType = "Include"  
          type = "SqlElasticPool" 
          / * if no elastic pool, use only serverName */
          serverName = azurerm_mssql_server.server.name
        }
      ]
    }
  })
}
```

## Creating Jobs

We are job creators! Or at least creators of elastic jobs.

This will create a job that will run once a day at 23:00 UTC. Make sure to schedule the startTime for the future or it will kick off right away and then at it's scheduled time, as well. 

```
resource "azapi_resource" "job" {
  type = "Microsoft.Sql/servers/jobAgents/jobs@2023-05-01-preview"
  name = "OlaStatsUpdateJob"
  parent_id = azapi_resource.elasticjobagent.id
  body = jsonencode({
    properties = {
      description = "Runs ola stats update only on all dbs in the target group"
      schedule = {
        enabled: true
        startTime: "2024-04-16T23:00:00Z"
        endTime: "9999-12-31T11:59:59Z"
        interval: "P1D"
        type: "Recurring"
      }
    }
  })
}
```

And this will add two steps to it. Note that you don’t specify the step number on the additional steps after step 1 because it will error out. If you add a stepid to any step after the first one, you will get an error.

Also, don’t mess around with the spacing on the SQL in the value parameter. It never works out well for me. Yes, it looks messy, but if I rearrange it, it tends to break the job.

```
resource "azapi_resource" "jobstep1" {
  type = "Microsoft.Sql/servers/jobAgents/jobs/steps@2023-05-01-preview"
  name = "OlaStatsUpdateStep"
  parent_id = azapi_resource.job.id
  body = jsonencode({
    properties = {
      action = {
        source = "Inline"
        type = "TSql"
        value = "EXECUTE [dbo].[IndexOptimize]\n            @Databases = 'USER_DATABASES' ,\n            @FragmentationLow = NULL ,\n            @FragmentationMedium = NULL ,\n            @FragmentationHigh = NULL ,\n            @UpdateStatistics = 'ALL' ,\n            @LogToTable = 'Y';"
      }
      stepId = 1
      targetGroup = azapi_resource.elasticjobstargetgroups.id
    }
  })
}

resource "azapi_resource" "jobstep2" {
  type = "Microsoft.Sql/servers/jobAgents/jobs/steps@2023-05-01-preview"
  name = "OlaCommandLogCleanupStep"
  parent_id = azapi_resource.job.id
  body = jsonencode({
    properties = {
      action = {
        source = "Inline"
        type = "TSql"
        value = "DELETE FROM [dbo].[CommandLog]\n WHERE StartTime <= DATEADD(DAY, -30, GETDATE());"
      }
      targetGroup = azapi_resource.elasticjobstargetgroups.id
    }
  })
}
```

That’s all there is to it. I know it might seem like a lot at first glance, but if you’ve set up an Elastic Job Agent and jobs before, it’s not too bad, or if you are familiar with Terraform, it’s quite straightforward.

## Checking on Your Job

You can see executions of your job in the Azure portal, but it’s difficult to impossible to see any error messages there.

It’s better to use a SQL query while connected to your agent db. Here’s [more on troubleshooting Elastic Jobs](https://techcommunity.microsoft.com/t5/azure-sql-blog/troubleshooting-common-issues-with-elastic-jobs-in-azure-sql/ba-p/1180766) and different errors.

```sql
SELECT *  
FROM jobs.job_executions  
ORDER BY start_time DESC 
```

