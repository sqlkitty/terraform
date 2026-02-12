# Get your user
/*data "azuread_user" "me" {
  user_principal_name = "azure_meowmanager.mozmail.com#EXT#@azuremeowmanagermozmail.onmicrosoft.com"
}*/

# Create the group
resource "azuread_group" "dbadmins" {
  display_name     = "dbadmins"
  security_enabled = true
}

# Add yourself to the group
/*
resource "azuread_group_member" "me" {
  group_object_id  = azuread_group.dbadmins.id
  member_object_id = data.azuread_user.me.object_id
}*/