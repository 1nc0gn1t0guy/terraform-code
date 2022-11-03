locals {
  registration_token = azurerm_virtual_desktop_host_pool_registration_info.hp.token
  shutdown_command   = "shutdown -r -t 10"
  exit_code_hack     = "exit 0"
  commandtorun       = "New-Item -Path HKLM:/SOFTWARE/Microsoft/RDInfraAgent/AADJPrivate"
  powershell_command = "${local.commandtorun}; ${local.shutdown_command}; ${local.exit_code_hack}"
}

#################################
# Installation of AVD agent and #
# Azure Active Directory        #
#################################

resource "azurerm_virtual_machine_extension" "AVDModule" {
  depends_on = [
    azurerm_windows_virtual_machine.avd_sessionhost
  ]
  count                = var.vm_count
  name                 = "Microsoft.PowerShell.DSC"
  virtual_machine_id   = azurerm_windows_virtual_machine.avd_sessionhost.*.id[count.index]
  publisher            = "Microsoft.Powershell"
  type                 = "DSC"
  type_handler_version = "2.73"
  settings             = <<-SETTINGS
    {
        "modulesUrl": "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_11-22-2021.zip",
        "ConfigurationFunction": "Configuration.ps1\\AddSessionHost",
        "Properties" : {
          "hostPoolName" : "${azurerm_virtual_desktop_host_pool.hp.name}",
          "aadJoin": true
        }
    }
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
  {
    "properties": {
      "registrationInfoToken": "${local.registration_token}"
    }
  }
PROTECTED_SETTINGS

}

resource "azurerm_virtual_machine_extension" "AADLoginForWindows" {
  depends_on = [
    azurerm_windows_virtual_machine.avd_sessionhost,
    azurerm_virtual_machine_extension.AVDModule
  ]
  count                      = var.vm_count
  name                       = "AADLoginForWindows"
  virtual_machine_id         = azurerm_windows_virtual_machine.avd_sessionhost.*.id[count.index]
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADLoginForWindows"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
}

resource "azurerm_virtual_machine_extension" "addaadjprivate" {
  depends_on = [
    azurerm_virtual_machine_extension.AADLoginForWindows
  ]
  count                = var.vm_count
  name                 = "AADJPRIVATE"
  virtual_machine_id   = azurerm_windows_virtual_machine.avd_sessionhost.*.id[count.index]
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell.exe -Command \"${local.powershell_command}\""
    }
SETTINGS
}
