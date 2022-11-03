########################
# Creation of hostpool #
########################

resource "time_rotating" "avd_token" {
  rotation_days = 30
}

resource "azurerm_virtual_desktop_host_pool" "hp" {
  custom_rdp_properties            = "targetisaadjoined:i:1;drivestoredirect:s:;audiomode:i:0;videoplaybackmode:i:1;redirectclipboard:i:0;redirectprinters:i:0;devicestoredirect:s:;redirectcomports:i:0;redirectsmartcards:i:0;usbdevicestoredirect:s:;enablecredsspsupport:i:1;redirectwebauthn:i:1;use multimon:i:1;enablerdsaadauth:i:1;camerastoredirect:s:;"
  description                      = "Created through the Azure Virtual Desktop extension"
  load_balancer_type               = "Persistent"
  location                         = var.hostpool_location
  name                             = "hp"
  preferred_app_group_type         = "Desktop"
  resource_group_name              = data.azurerm_resource_group.rg.name
  start_vm_on_connect              = false
  type                             = "Personal"
  personal_desktop_assignment_type = "Automatic"
  validate_environment             = false

  timeouts {}
}

resource "azurerm_virtual_desktop_host_pool_registration_info" "hp" {
  hostpool_id     = azurerm_virtual_desktop_host_pool.hp.id
  expiration_date = time_rotating.avd_token.rotation_rfc3339
}

#############
# workspace #
#############

resource "azurerm_virtual_desktop_workspace" "avd" {
  name                = "workspace"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  friendly_name = "Workspace"
  description   = "Workspace"
}

resource "azurerm_virtual_desktop_application_group" "avd" {
  name                = "vdag"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  type                         = "Desktop"
  host_pool_id                 = azurerm_virtual_desktop_host_pool.hp.id
  friendly_name                = "AppGroup"
  default_desktop_display_name = "AppGroup"
  description                  = "AppGroup"
}

resource "azurerm_virtual_desktop_workspace_application_group_association" "avd" {
  workspace_id         = azurerm_virtual_desktop_workspace.avd.id
  application_group_id = azurerm_virtual_desktop_application_group.avd.id
}
