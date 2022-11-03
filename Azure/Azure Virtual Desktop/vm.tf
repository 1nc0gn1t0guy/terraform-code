#############################################################
# Creation of Virtual machine using the existing network ####
# and existing HostPool                                  ####
#############################################################

resource "azurerm_network_interface" "sessionhost_nic" {
  count               = var.vm_count
  name                = "${var.vm_nic_name}-${count.index + 1}-nic"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "${var.vm_nic_ip_name}-${count.index + 1}-ip"
    subnet_id                     = data.azurerm_subnet.vnet_subnet.id
    private_ip_address_allocation = var.vm_nic_pip_allocation
  }
}

resource "azurerm_windows_virtual_machine" "avd_sessionhost" {
  depends_on = [
    azurerm_network_interface.sessionhost_nic
  ]


  count               = var.vm_count
  name                = "${var.vm_name}-${count.index + 1}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  size                = var.vm_size
  admin_username      = data.azurerm_key_vault_secret.vmUser.value
  admin_password      = data.azurerm_key_vault_secret.vmPass.value
  provision_vm_agent  = true

  network_interface_ids = ["${azurerm_network_interface.sessionhost_nic.*.id[count.index]}"]

  source_image_id = data.azurerm_shared_image.avd_image.id

  identity {
    type = var.vm_identity
  }

  os_disk {
    name                 = "${lower(var.vm_osdisk_name)}-${count.index + 1}"
    caching              = var.vm_osdisk_caching
    storage_account_type = var.vm_osdisk_satype
    disk_size_gb         = var.vm_osdisk_size
  }
}
