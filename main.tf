provider "azurerm" {
  version = "=1.36.0"
  #subscription_id = "########-#########-##########"
}

resource "azurerm_resource_group" "atlanticgroup" {
    name     = "TerraResourceGroup"
    location = "uksouth"

    tags = {
        environment = "Production"
    }
}

resource "azurerm_virtual_network" "atlanticnetwork1" {
    name                = "Vnet1"
    address_space       = ["10.0.0.0/16"]
    location            = "uksouth"
    resource_group_name = "${azurerm_resource_group.atlanticgroup.name}"

    tags = {
        environment = "Production"
    }
}

resource "azurerm_subnet" "atlanticsubnet1" {
    name                 = "Subnet1"
    resource_group_name  = "${azurerm_resource_group.atlanticgroup.name}"
    virtual_network_name = "${azurerm_virtual_network.atlanticnetwork1.name}"
    address_prefix       = "10.0.2.0/24"
}

resource "azurerm_public_ip" "atlanticpublicip" {
    name                         = "PublicIP"
    location                     = "uksouth"
    resource_group_name          = "${azurerm_resource_group.atlanticgroup.name}"
    allocation_method            = "Dynamic"

    tags = {
       environment = "Production"
    }
}

resource "azurerm_network_security_group" "atlanticnsg1" {
    name                = "AtlanticNSG"
    location            = "uksouth"
    resource_group_name = "${azurerm_resource_group.atlanticgroup.name}"
    
    security_rule {
        name                       = "RDP"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "3389"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }


    tags = {
        environment = "Production"
    }
}

resource "azurerm_network_interface" "atlanticnic1" {
    name                        = "atlanticnic1"
    location                    = "uksouth"
    resource_group_name         = "${azurerm_resource_group.atlanticgroup.name}"
    network_security_group_id   = "${azurerm_network_security_group.atlanticnsg1.id}"

    ip_configuration {
        name                          = "NicConfiguration"
        subnet_id                     = "${azurerm_subnet.atlanticsubnet1.id}"
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = "${azurerm_public_ip.atlanticpublicip.id}"
    }

    tags = {
        environment = "Production"
    }
}

resource "azurerm_virtual_machine" "atlanticvm" {
    name                  = "AtlanticVM"
    location              = "uksouth"
    resource_group_name   = "${azurerm_resource_group.atlanticgroup.name}"
    network_interface_ids =  ["${azurerm_network_interface.atlanticnic1.id}"]
  
    vm_size               = "Standard_DS1_v2"
    
    os_profile_windows_config {
    provision_vm_agent = true

}
    storage_os_disk {
        name              = "OsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Standard_LRS"
    }

   storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

    os_profile {
        computer_name  = "atlanticvm"
        admin_username = "azureuser"
        admin_password = "${var.admin_password}"
    }

    tags = {
        environment = "Production"
    }
}

#resource "azurerm_virtual_machine_extension" "domjoin" {
#name = "domjoin"
#location = "uksouth"
#resource_group_name = "${azurerm_resource_group.atlanticgroup.name}"
#virtual_machine_name = "terravm"
#publisher = "Microsoft.Compute"
#type = "JsonADDomainExtension"
#type_handler_version = "1.3"
#settings = <<SETTINGS
#{
#"Name": "deise.com",
#"OUPath": "OU=Servers,DC=deise,DC=com",
#"User": "deise.com\\pr_admin",
#"Restart": "true",
#"Options": "3"
#}
#SETTINGS
#protected_settings = <<PROTECTED_SETTINGS
#{
#"Password": "${var.admin_password}"
#}
#PROTECTED_SETTINGS
#depends_on = ["azurerm_virtual_machine.terraformvm"]
#}   
